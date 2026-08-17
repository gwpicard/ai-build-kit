# SOURCES.md: what this kit borrowed, and from whom

AI Build Kit took ideas from other people working in the open. This page names
that work and says what each piece of it contributed. It is a credit list for
borrowed ideas rather than a list of everything the kit depends on. Why the kit
is shaped the way it is belongs to [PHILOSOPHY.md](PHILOSOPHY.md), so every
line here credits a source and stops there.

Nobody named here was asked first, and nobody named here has endorsed the kit.

| Source | What it gave the kit |
|---|---|
| [28 Days of Lovable](https://28daysoflovable.com/), Lazar Jovanovic's course for Lovable | `masterplan.md`'s name and its job, the set of project records and the reason for keeping them, and the working rhythm of taking the next item and saying how it will be checked |
| [mattpocock/skills](https://github.com/mattpocock/skills) | The agent's best guess attached to every interview question, the throwaway prototype built to settle one argument, the habit of building a reliable way to reproduce a fault before reading any code, and recording on a piece which kind of question is holding it up, so the reason outlives the conversation that found it |
| [obra/superpowers](https://github.com/obra/superpowers) | One question at a time, the rule that three failed repair attempts mean stop patching, and a reviewer that did not do the work and never sees the conversation that produced it |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | The unattended run that builds several pieces after one approval, why a wrong guess is easier to correct than a blank question, and the rule that a supplier's own documentation beats a tutorial or the agent's memory |
| [tw93/waza](https://github.com/tw93/waza) | A hard ceiling on how many commands the person ever has to learn, with every new ability arriving inside a command that already exists |
| [Agent Flywheel](https://agent-flywheel.com/complete-guide), by Jeffrey Emanuel | The list of commands that quietly destroy work, the gap between a rule that is written down and one the tool enforces, and changing the instructions rather than the output when an unattended run disappoints |
| [Alex Lavaee on the new software lifecycle](https://alexlavaee.me/blog/new-sdlc-agentic-engineering/) | The position that the documents are the asset and the code is their current expression |
| [Mateusz Jacniacki, "Don't read the code"](https://matijacniacki.com/blog/dont-read-the-code) | That nobody has to read the code or the logs, and that the built thing gets checked against the document by something which did not build it |
| [Dex Horthy, "Advanced Context Engineering for Agents"](https://www.youtube.com/watch?v=VvkhYWFWaKI) | Cutting each piece of work through the whole tool rather than building one layer at a time, and the warning that a workflow needing secret phrasing is already broken |
| [Damien C. Tanner, on how Toyo works](https://x.com/dctanner/status/2034318024673464644) | Grading a change by what it could damage and letting that decide the checking, a non-engineer building the first version while an engineer stays accountable for quality, and the prototype becoming the brief a professional rebuilds from. He described the grading as an experiment his team was running at the time |
| [Simon Willison on agentic engineering](https://simonwillison.net/guides/agentic-engineering-patterns/) | That a passing test suite is not proof on its own, which is why a guided look counts as evidence here, and that a report has to say what was actually run and what actually came out |
| [Maxi Contieri's notes on coding with agents](https://dev.to/mcsee/series/34999) | Saving your work before letting the agent loose on it, and a reviewer that did not do the work, because whoever built something is anchored to what they meant to build |
| [Geoffrey Huntley on the Ralph technique](https://ghuntley.com/ralph/) | Changing the instructions and running it again when an unattended run goes wrong |
| [Clayton Farr's Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook) | The clearest written version of that same rule, compiled from Huntley's technique and credited to him |
| [Boris Cherny's notes on Claude Code](https://ykdojo.github.io/claude-code-tips/content/boris-claude-code-tips) | Turning something you have done more than once into a saved shortcut |
| [Carsten Jørgensen on harness engineering](https://harness-engineering.carstenj.workers.dev/) | That a rule written down is a wish and a rule the tool enforces is a law, which is why the dangerous commands are switched off rather than discouraged |
| [trailofbits/skills](https://github.com/trailofbits/skills) | That a check inspecting nothing has to fail rather than pass, which is why a new project starts with a deliberately failing check |
| [Builder.io on subagents](https://www.builder.io/blog/subagents) | That whoever built something is the worst judge of whether it works, so a reviewer that did not do the work is the one worth having |
| [EveryInc's compound engineering plugin](https://github.com/EveryInc/compound-engineering-plugin) | That independence is a property of the separate run rather than of the point of view taken, so a review done in the same conversation gets labelled as the weaker thing it is |
| ["How we vibe code at a FAANG"](https://www.reddit.com/r/vibecoding/comments/1myakhd/how_we_vibe_code_at_a_faang/) | A hard read of the plan before any building starts, on the grounds that a problem found on paper is the cheapest one to fix |
