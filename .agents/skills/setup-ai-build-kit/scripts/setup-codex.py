#!/usr/bin/env python3
"""Install the Codex check, or apply a shell change the person approved."""
import argparse
import json
import os
from pathlib import Path
import shlex
import sys

SKILL = Path(__file__).resolve().parents[1]
BEGIN = "# BEGIN AI Build Kit codex launcher"
END = "# END AI Build Kit codex launcher"
BLOCK = '''# BEGIN AI Build Kit codex launcher
codex() {
  local abk_dir="$PWD" abk_launcher abk_skill_folder
  while [ "$abk_dir" != / ]; do
    if [ -f "$abk_dir/.agents/tools/codex-github-check.py" ]; then
      abk_launcher=$(python3 "$abk_dir/.agents/tools/codex-github-check.py" --launcher) || abk_launcher=
      if [ -f "$abk_launcher" ]; then
        python3 "$abk_launcher" "$@"
        return $?
      fi
    fi
    for abk_skill_folder in .agents/skills .claude/skills agent-plugin/skills; do
      abk_launcher="$abk_dir/$abk_skill_folder/setup-ai-build-kit/scripts/codex-with-github.py"
      if [ -f "$abk_launcher" ]; then
        python3 "$abk_launcher" "$@"
        return $?
      fi
    done
    if [ -e "$abk_dir/.git" ] || [ -f "$abk_dir/AGENTS.md" ]; then break; fi
    abk_dir=${abk_dir%/*}
    [ -n "$abk_dir" ] || abk_dir=/
  done
  command codex "$@"
}
# END AI Build Kit codex launcher
'''


def safe_path(path):
    for part in (path, *path.parents):
        if part.is_symlink():
            raise ValueError(f"{part} is a link, so it was left alone")
    if path.exists() and not path.is_file():
        raise ValueError(f"{path} is not a file, so it was left alone")


def write_if_changed(path, content):
    safe_path(path)
    if path.exists() and path.read_bytes() == content:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)


def install_hooks(project):
    helper = project / ".agents/tools/codex-github-check.py"
    pointer = project / ".agents/tools/codex-setup-path"
    hooks_file = project / ".codex/hooks.json"
    for path in (helper, pointer, hooks_file):
        safe_path(path)
    data = json.loads(hooks_file.read_text()) if hooks_file.exists() else {}
    hooks = data.setdefault("hooks", {})
    entries = hooks.setdefault("SessionStart", [])
    # Only this kit's handler is replaced. Keep all other events and handlers.
    def kit_handler(handler):
        try:
            parts = shlex.split(handler.get("command", ""))
        except ValueError:
            return False
        return (len(parts) == 3 and parts[0] == "python3" and parts[2] == "--hook"
                and Path(parts[1]).name == "codex-github-check.py")
    for entry in entries:
        entry["hooks"] = [h for h in entry.get("hooks", []) if not kit_handler(h)]
    entries[:] = [entry for entry in entries if entry.get("hooks")]
    command = "python3 " + shlex.quote(str(helper)) + " --hook"
    entries.append({"hooks": [{"type": "command", "command": command,
                              "timeout": 20}]})
    write_if_changed(helper, (SKILL / "templates/foundation/codex-github-check.py").read_bytes())
    write_if_changed(pointer, (str(SKILL) + "\n").encode())
    write_if_changed(hooks_file, (json.dumps(data, indent=2) + "\n").encode())
    print("The GitHub check is installed. Trust this project and review its new or changed hook with /hooks in Codex, then restart the session.")


def shell_file():
    shell = Path(os.environ.get("SHELL", "")).name
    if shell not in ("zsh", "bash"):
        raise ValueError("The shell offer supports zsh and bash; use the launcher command in this shell.")
    return Path.home() / (".zshrc" if shell == "zsh" else ".bash_profile")


def shell_change(path, remove=False):
    safe_path(path)
    text = path.read_text() if path.exists() else ""
    lines = text.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.rstrip("\r\n") == BEGIN]
    ends = [i for i, line in enumerate(lines) if line.rstrip("\r\n") == END]
    if starts or ends:
        if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
            raise ValueError("The launcher block is incomplete or repeated; the shell file was left alone.")
        text = "".join(lines[:starts[0]]) + ("" if remove else BLOCK) + "".join(lines[ends[0]+1:])
    elif not remove:
        text += ("\n" if text and not text.endswith("\n") else "") + BLOCK
    write_if_changed(path, text.encode())


def record(project, choice):
    path = project / ".ai-build-kit-maintenance"
    safe_path(path)
    text = path.read_text() if path.exists() else ""
    lines = [line for line in text.splitlines() if not line.startswith("codex-shell|")]
    lines.append("codex-shell|" + choice)
    write_if_changed(path, ("\n".join(lines) + "\n").encode())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    for name in ("hooks", "shell-status", "shell-install", "shell-decline", "shell-remove"):
        action.add_argument("--" + name, action="store_true")
    parser.add_argument("project", nargs="?", default=".")
    args = parser.parse_args()
    project = Path(args.project).resolve()
    if not (project / "AGENTS.md").is_file():
        raise ValueError("This folder has no project instructions; prepare the kit project first.")
    if (project / "release-manifest.txt").exists() and (project / "docs/MAINTAINING.md").exists():
        raise ValueError("Codex project setup does not run in the kit's maintainer source.")
    if args.hooks:
        install_hooks(project)
        return
    if args.shell_decline:
        record(project, "declined")
        return
    path = shell_file()
    if args.shell_status:
        maintenance = project / ".ai-build-kit-maintenance"
        if maintenance.exists() and any(line.startswith("codex-shell|") for line in maintenance.read_text().splitlines()):
            return
        safe_path(path)
        if path.exists() and BEGIN in path.read_text():
            print(f"The Codex launcher block is already in {path}; no new offer is needed.")
            return
        print(f"May I add a function to {path} so typing codex in a kit project uses the launcher? Outside a kit project it runs Codex as usual. To undo it, remove the block between '{BEGIN}' and '{END}' and open a new terminal.")
        return
    safe_path(project / ".ai-build-kit-maintenance")
    shell_change(path, remove=args.shell_remove)
    record(project, "removed" if args.shell_remove else "installed")
    print(f"The launcher block was {'removed from' if args.shell_remove else 'saved in'} {path}. Open a new terminal to use the change.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, TypeError, KeyError) as error:
        sys.exit("Codex setup stopped: " + str(error))
