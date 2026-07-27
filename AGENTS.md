# Project agent instructions

These instructions apply to the entire repository.

## Delivery workflow

1. Treat `docs/implementation-plan.md` as the source of truth for implementation status. Update it whenever a step starts, completes, or changes scope.
2. Complete work in small, independently verifiable implementation steps. Do not mix unrelated features in one step.
3. Before declaring a step complete, run the relevant Godot parse/import check, automated tests, and proportional export or visual checks.
4. After each completed step, create one focused Git commit and push the current branch to `origin`. Do not leave completed implementation steps only in the working tree.
5. If commit or push fails, keep the verified changes intact and report the exact blocker. Never rewrite or discard user-owned history to make a push succeed.

## Safety and repository hygiene

- Never commit API keys, `.env.local`, account credentials, child identity data, textbook scans, or unlicensed assets.
- Keep MiniMax and other service calls in offline development tools. Do not embed credentials or runtime model calls in Web or APK exports.
- Preserve user changes and unrelated files. Avoid destructive Git commands.
- Keep generated exports under `build/`; do not commit export artifacts unless explicitly requested.

## Product and content constraints

- Engine: Godot 4.7, GDScript, 2D, landscape 1280×720 baseline.
- Primary releases: Web and Android APK. Treat WeChat Mini Game as a later feasibility spike.
- Target children may not read. Pair every essential instruction with replayable speech and visual highlighting.
- Use positive, non-punitive feedback. Wrong answers must not remove lives, shame the child, or end the session.
- Drive curriculum content from validated JSON. Keep unverified textbook topics disabled until source pages or a reliable table of contents confirm them.
- Use original art. Keep countable objects as individual sprites controlled by game logic.

## Standard verification commands

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path /Users/xuanyuan/Documents/godotwork/pet-math-town --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/xuanyuan/Documents/godotwork/pet-math-town --scene res://tests/run_tests.tscn
```

