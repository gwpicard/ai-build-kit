#!/usr/bin/env sh
# Rehearse session-scoped GitHub credentials without an account or a network.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PYTEST'
import json, os, pathlib, subprocess, sys, tempfile, shutil
root = pathlib.Path(sys.argv[1])
launcher = root / ".agents/skills/setup-ai-build-kit/scripts/codex-with-github.py"
if not launcher.is_file():
    sys.exit("FAIL: the installed skill has no portable Codex credential launcher")
failures = []
with tempfile.TemporaryDirectory() as folder:
    folder = pathlib.Path(folder)
    fixture = "synthetic-not-a-github-credential"
    gh = folder / "gh"
    gh.write_text("#!" + sys.executable + "\n" +
        'import os, sys\n'
        'assert sys.argv[1:] == ["auth", "token", "--hostname", "github.com"]\n'
        'mode = os.environ.get("FIXTURE_MODE", "success")\n'
        'if mode == "refuse": sys.exit(1)\n'
        'print(os.environ["FIXTURE_CREDENTIAL"])\n'
        'if mode == "multiline": print("extra line")\n'
        'if mode == "failure": sys.exit(1)\n')
    gh.chmod(0o700)
    codex = folder / "codex"
    codex.write_text("#!" + sys.executable + "\n" +
        'import json, os, sys\n'
        'credential = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")\n'
        'print(json.dumps({"authenticated": credential == os.environ["FIXTURE_CREDENTIAL"], '
        '"args": sys.argv[1:], "profile": os.environ.get("CODEX_PERMISSION_PROFILE"), '
        '"debug": "GH_DEBUG" in os.environ, '
        '"git_settings": [[os.environ["GIT_CONFIG_KEY_" + str(i)], os.environ["GIT_CONFIG_VALUE_" + str(i)]] '
        'for i in range(int(os.environ.get("GIT_CONFIG_COUNT", "0")))]}))\n')
    codex.chmod(0o700)
    base = {k:v for k,v in os.environ.items() if k not in ["GH_TOKEN", "GITHUB_TOKEN"] and not k.startswith("GIT_CONFIG_")}
    base.update(PATH=str(folder), FIXTURE_CREDENTIAL=fixture, CODEX_PERMISSION_PROFILE="workspace-network")
    def run(name, changes, success, args=None):
        env = dict(base); env.update(changes)
        result = subprocess.run([sys.executable, str(launcher), *(args or [])], env=env, capture_output=True, text=True)
        text = result.stdout + result.stderr
        ok = fixture not in text
        if success:
            try:
                data = json.loads(result.stdout)
                ok = ok and result.returncode == 0 and data["authenticated"]
                ok = ok and data["profile"] == "workspace-network" and not data["debug"]
                ok = ok and data["args"] == ["--no-daemon", "--disable", "shell_snapshot", *(args or [])]
                inherited = [[env["GIT_CONFIG_KEY_" + str(i)], env["GIT_CONFIG_VALUE_" + str(i)]]
                             for i in range(int(env.get("GIT_CONFIG_COUNT", "0")))]
                ok = ok and data["git_settings"] == inherited + [
                    ["credential.https://github.com.helper", ""],
                    ["credential.https://github.com.helper", "!gh auth git-credential"]]
            except (ValueError, KeyError): ok = False
        else: ok = ok and result.returncode != 0 and not result.stdout
        print(("ok: " if ok else "FAIL: ") + name)
        if not ok: failures.append(name)
    run("stored credential stays in memory and arguments survive", {"GH_DEBUG":"api"}, True, ["exec", "a prompt with 'quotes'"])
    run("existing GH_TOKEN needs no stored login", {"GH_TOKEN":fixture,"FIXTURE_MODE":"refuse"}, True)
    run("existing GITHUB_TOKEN needs no stored login", {"GITHUB_TOKEN":fixture,"FIXTURE_MODE":"refuse"}, True)
    run("failed credential read never launches Codex or prints its output", {"FIXTURE_MODE":"failure"}, False)
    run("malformed credential response never launches Codex", {"FIXTURE_MODE":"multiline"}, False)
    run("inherited Git settings survive before the session helpers", {
        "GIT_CONFIG_COUNT":"1", "GIT_CONFIG_KEY_0":"core.autocrlf", "GIT_CONFIG_VALUE_0":"false"}, True)
    run("incomplete Git settings start no session", {"GIT_CONFIG_COUNT":"1"}, False)
    run("invalid Git settings start no session", {"GIT_CONFIG_COUNT":"wrong"}, False)

    # Exercise Git itself, including its helper reset. No network or account.
    git = shutil.which("git")
    global_file = folder / "gitconfig"
    global_file.write_text('[credential "https://github.com"]\n\thelper = !echo KEYCHAIN-WAS-CALLED >&2; exit 1\n')
    before = global_file.read_bytes()
    gh.write_text("#!" + sys.executable + "\n" +
        'import os, sys\n'
        'if sys.argv[1:3] == ["auth", "token"]: print(os.environ["FIXTURE_CREDENTIAL"])\n'
        'elif sys.argv[1:3] == ["auth", "git-credential"]:\n'
        '    sys.stdin.read()\n'
        '    print("username=fixture\\npassword=" + os.environ["GH_TOKEN"])\n'
        'else: sys.exit(1)\n')
    codex.write_text("#!" + sys.executable + "\n" +
        'import os, subprocess, sys\n'
        'r = subprocess.run([os.environ["REAL_GIT"], "credential", "fill"], '
        'input="protocol=https\\nhost=github.com\\n\\n", capture_output=True, text=True)\n'
        'assert r.returncode == 0 and "KEYCHAIN-WAS-CALLED" not in r.stderr\n'
        'assert "password=" + os.environ["FIXTURE_CREDENTIAL"] in r.stdout\n'
        'print("git authenticated")\n')
    env = dict(base, PATH=str(folder) + os.pathsep + os.defpath,
               REAL_GIT=git, GIT_CONFIG_GLOBAL=str(global_file), GIT_CONFIG_NOSYSTEM="1")
    result = subprocess.run([sys.executable, str(launcher)], env=env, capture_output=True, text=True)
    ok = result.returncode == 0 and result.stdout.strip() == "git authenticated" and global_file.read_bytes() == before
    print(("ok: " if ok else "FAIL: ") + "Git uses gh instead of the Keychain and leaves global settings alone")
    if not ok: failures.append("real Git helper reset")
    gh.unlink()
    run("missing GitHub CLI stops the launch", {}, False)
    codex.unlink()
    run("missing Codex stops the launch", {}, False)

with tempfile.TemporaryDirectory(prefix="codex project ") as temp:
    folder = pathlib.Path(temp).resolve()
    project = folder / "project"
    project.mkdir()
    (project / "AGENTS.md").write_text("Project instructions\n")
    (project / "masterplan.md").write_text("A founded project\n")
    home = folder / "home"; home.mkdir()
    bin_dir = folder / "bin"; bin_dir.mkdir()
    gh = bin_dir / "gh"
    gh.write_text("#!" + sys.executable + "\nimport os, sys\n"
                  'if os.environ.get("FAIL_AUTH"): print("HTTP 401 token=synthetic-private-value", file=sys.stderr); sys.exit(1)\n'
                  'if sys.argv[1:3] == ["auth", "status"] and ("--active" not in sys.argv or "--hostname" not in sys.argv or "github.com" not in sys.argv): print("Inactive saved account is invalid", file=sys.stderr); sys.exit(1)\n'
                  'if sys.argv[1:3] == ["repo", "view"]: print("{}")\n')
    gh.chmod(0o700)
    env = {k:v for k,v in os.environ.items() if k not in ("GH_TOKEN", "GITHUB_TOKEN", "CODEX_THREAD_ID", "CODEX_SANDBOX")}
    env.update(HOME=str(home), SHELL="/bin/zsh", PATH=str(bin_dir) + os.pathsep + os.environ["PATH"], CODEX_THREAD_ID="fixture")
    setup = launcher.with_name("setup-codex.py")
    check = launcher.parent.parent / "templates/foundation/codex-github-check.py"
    def assert_case(name, ok):
        print(("ok: " if ok else "FAIL: ") + name)
        if not ok: failures.append(name)
    def command(script, *args, extra=None, stdin=None, cwd=project):
        return subprocess.run([sys.executable, str(script), *args], cwd=cwd,
                              env=dict(env, **(extra or {})), input=stdin, capture_output=True, text=True)

    hooks = project / ".codex/hooks.json"; hooks.parent.mkdir()
    personal = {"type":"command", "command":"echo personal"}
    hooks.write_text(json.dumps({"personal": True, "hooks":{"SessionStart":[{"hooks":[personal]}], "Stop":[{"hooks":[personal]}]}}))
    installed = command(setup, "--hooks")
    before = hooks.read_bytes()
    second = command(setup, "--hooks")
    data = json.loads(hooks.read_text())
    assert_case("hook installation preserves other handlers and is repeatable", installed.returncode == second.returncode == 0 and
                hooks.read_bytes() == before and data["personal"] and data["hooks"]["Stop"][0]["hooks"] == [personal] and
                data["hooks"]["SessionStart"][0]["hooks"] == [personal])
    copied = project / ".agents/tools/codex-github-check.py"
    result = command(copied, "--hook", stdin=json.dumps({"cwd":str(project)}))
    assert_case("authenticated session check stays silent", result.returncode == 0 and not result.stdout and not result.stderr)
    result = command(copied)
    assert_case("an inactive saved account cannot reject the working session login", result.returncode == 0 and not result.stdout and not result.stderr)
    report = subprocess.run(["sh", str(launcher.with_name("check-tooling.sh"))], cwd=project,
                            env=env, capture_output=True, text=True)
    assert_case("tooling checks only the active GitHub account", report.returncode == 0 and
                "you are signed in" in report.stdout and "Quit and start Codex" not in report.stdout)
    result = command(copied, "--hook", extra={"FAIL_AUTH":"1"}, stdin=json.dumps({"cwd":str(project)}))
    data = json.loads(result.stdout)
    assert_case("failed session hook stops work with an absolute restart command", data["continue"] is False and
                str(launcher.resolve()) in data["systemMessage"] and "gh auth login" not in result.stdout and "synthetic-private" not in result.stdout)
    result = command(copied, extra={"FAIL_AUTH":"1"})
    assert_case("instruction fallback fails before work and prints only the restart sentence", result.returncode == 1 and
                str(launcher.resolve()) in result.stdout and len(result.stdout.splitlines()) == 1 and not result.stderr)
    # Installed skills can live under either shared folder or outside a plugin project.
    for layout in (".agents/skills", ".claude/skills", "agent-plugin/skills"):
        dest = project / layout / "setup-ai-build-kit"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.symlink_to(launcher.parent.parent, target_is_directory=True)
        result = command(copied, "--launcher")
        assert_case("launcher resolves through " + layout, result.stdout.strip() == str(launcher.resolve()))
        dest.unlink()
    result = command(copied, "--launcher")
    assert_case("plugin launcher resolves through its recorded installed path", result.stdout.strip() == str(launcher.resolve()))

    shell = home / ".zshrc"
    shell.write_text("# personal setting\nexport PERSONAL=kept\n")
    shell_before = shell.read_bytes()
    offered = command(setup, "--shell-status")
    assert_case("shell offer names its file and undo while changing nothing", str(shell) in offered.stdout and
                "undo" in offered.stdout and shell.read_bytes() == shell_before)
    command(setup, "--shell-decline")
    assert_case("declined shell offer stays declined on resume", not command(setup, "--shell-status").stdout and shell.read_bytes() == shell_before)
    command(setup, "--shell-install")
    shell_after = shell.read_bytes()
    command(setup, "--shell-install")
    assert_case("approved shell block preserves personal settings and updates once", shell.read_bytes() == shell_after and
                shell_after.startswith(shell_before) and shell_after.count(b"# BEGIN AI Build Kit") == 1)
    # A fake binary records whether the function reached the launcher, without a model call.
    codex = bin_dir / "codex"
    codex.write_text("#!" + sys.executable + "\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n")
    codex.chmod(0o700)
    shell_env = dict(env, GH_TOKEN="synthetic-not-a-github-credential")
    fresh = folder / "fresh installation"
    installed_skill = fresh / ".agents/skills/setup-ai-build-kit"
    installed_skill.parent.mkdir(parents=True)
    installed_skill.symlink_to(launcher.parent.parent, target_is_directory=True)
    for executable in (shutil.which("zsh"), shutil.which("bash")):
        if not executable: continue
        def start(cwd):
            return subprocess.run([executable, "-c", '. "$HOME/.zshrc"; codex exec "argument with spaces"'],
                                  cwd=cwd, env=shell_env, capture_output=True, text=True, timeout=10)
        result = start(project)
        assert_case(pathlib.Path(executable).name + " function reaches the binary without recursion", result.returncode == 0 and
                    json.loads(result.stdout) == ["--no-daemon", "--disable", "shell_snapshot", "exec", "argument with spaces"])
        result = start(fresh)
        assert_case(pathlib.Path(executable).name + " finds the installed launcher before founding", result.returncode == 0 and
                    json.loads(result.stdout) == ["--no-daemon", "--disable", "shell_snapshot", "exec", "argument with spaces"])
        nested = fresh / "subfolder"; nested.mkdir(exist_ok=True)
        result = start(nested)
        assert_case(pathlib.Path(executable).name + " finds the launcher from a project subfolder", result.returncode == 0 and
                    json.loads(result.stdout) == ["--no-daemon", "--disable", "shell_snapshot", "exec", "argument with spaces"])
        result = start(folder)
        assert_case(pathlib.Path(executable).name + " runs ordinary Codex outside kit projects", result.returncode == 0 and
                    json.loads(result.stdout) == ["exec", "argument with spaces"])
        pointer = project / ".agents/tools/codex-setup-path"
        pointer.write_text(str(folder / "missing") + "\n")
        result = start(project)
        assert_case(pathlib.Path(executable).name + " runs ordinary Codex when the launcher is missing", result.returncode == 0 and
                    json.loads(result.stdout) == ["exec", "argument with spaces"])
        pointer.write_text(str(launcher.parent.parent) + "\n")
    command(setup, "--shell-remove")
    assert_case("removing the marked block restores the personal shell file", shell.read_bytes() == shell_before)

    # Failure messages run from installed scripts, without the agent locating a reference.
    gh.write_text("#!" + sys.executable + "\nimport sys\nprint('HTTP 401: Requires authentication', file=sys.stderr)\nsys.exit(1)\n")
    report = subprocess.run(
        ["sh", str(launcher.with_name("check-tooling.sh"))], cwd=project, env=env, capture_output=True, text=True)
    assert_case("tool report 401 names the absolute launcher without re-login advice", report.returncode != 0 and
                str(launcher.resolve()) in report.stdout and "gh auth login" not in report.stdout + report.stderr)
    gh.write_text("#!" + sys.executable + "\nimport sys\n"
                  'if sys.argv[1:3] == ["auth", "status"]: sys.exit(0)\n'
                  'print("HTTP 401: Requires authentication", file=sys.stderr)\nsys.exit(1)\n')
    report = subprocess.run(["sh", str(launcher.with_name("check-tooling.sh"))], cwd=project,
                            env=env, capture_output=True, text=True)
    assert_case("repository 401 also stops the tool report with the launcher command", report.returncode != 0 and
                str(launcher.resolve()) in report.stdout and "gh auth login" not in report.stdout + report.stderr)
    plan = launcher.parent.parent / "templates/foundation/plan-refresh.sh"
    (project / "plan.local.md").write_text("Earlier printout\n")
    for error in ("HTTP 401: Requires authentication", "fatal: unable to get password from user"):
        gh.write_text("#!" + sys.executable + "\nimport sys\nprint(" + repr(error) + ", file=sys.stderr)\nsys.exit(1)\n")
        result = subprocess.run(["sh", str(plan)], cwd=project, env=env, capture_output=True, text=True)
        assert_case("plan failure gives the restart command for " + error, result.returncode != 0 and
                    str(launcher.resolve()) in result.stderr and "gh auth login" not in result.stderr and
                    (project / "plan.local.md").read_text() == "Earlier printout\n")
    result = command(copied, "--message")
    assert_case("Git failure recovery uses the same absolute command", str(launcher.resolve()) in result.stdout and
                "do not sign in again" in result.stdout and "gh auth login" not in result.stdout)
    for name in ("implement", "maintain", "section-builder"):
        source = " ".join((root / ".agents/skills" / name / "SKILL.md").read_text().split())
        assert_case(name + " sends Git password failures to the executable recovery message",
                    "unable to get password from user" in source and "codex-github-check.py" in source and "--message" in source)
    source = (launcher.parent.parent / "templates/foundation/AGENTS.md").read_text()
    assert_case("project instructions check access before reading the product records",
                source.index("codex-github-check.py") < source.index("masterplan.md") and "stop; start no work" in source)
    shell.write_text("# BEGIN AI Build Kit codex launcher\nunfinished\n")
    before = shell.read_bytes()
    result = command(setup, "--shell-install")
    assert_case("an incomplete shell block is refused without changing it", result.returncode != 0 and shell.read_bytes() == before)
    shell.unlink()
    external = folder / "personal-shell"; external.write_text("personal\n")
    shell.symlink_to(external)
    result = command(setup, "--shell-install")
    assert_case("a linked shell file is left alone", result.returncode != 0 and external.read_text() == "personal\n")
    hooks.unlink()
    hooks.symlink_to(external)
    result = command(setup, "--hooks")
    assert_case("linked hook settings are left alone", result.returncode != 0 and external.read_text() == "personal\n")
if failures: sys.exit(1)
print("codex-github-auth.sh: all checks passed")
PYTEST
