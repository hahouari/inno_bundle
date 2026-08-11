# AGENTS.md

## project

- `inno_bundle` = Dart CLI that bundles Flutter Windows apps into Inno Setup installers
- pub dev package, shipped to pub.dev
- entry points in `bin/`, lib in `lib/`, tests in `test/`
- example app in `example/demo_app` (real Flutter project, used as test fixture)

## platform

- target: Windows only (Flutter Windows + Inno Setup ISCC.exe)
- dev can happen on WSL/Linux — non-Windows tests must self-skip, never hard-fail
- run windows stuff via `pwsh.exe -NoProfile -Command "..."` from WSL

## before commit

- `dart analyze` — must pass, zero issues
- `dart format --set-exit-if-changed lib test tool` — must pass
- `dart test` — cross-platform tests green, Windows-only tests skip cleanly
- if format touches files you did NOT edit → `git checkout --` them, only your files should be in diff

## tests

- per-matrix tests live in `test/*_cross_version_test.dart`
- matrix = canonical Inno Setup versions, fetched live from GitHub, one latest patch per minor, no betas, floor 6.4.0
- no env vars to control test behavior — no `RUN_FLUTTER_BUILD`, no `INNO_VERSIONS_DIR`. tests skip themselves if Inno not installed or no token
- test configs must mirror real `example/demo_app/pubspec.yaml` (`admin: auto`, `arch: x64_compatible`). do NOT use id-only synthetic configs — they silently default to admin mode and pop UAC
- skip message must tell user exact command to fix (e.g. `dart run inno_bundle:setup_versions --versions <csv>`)
- windows-only = `skip: !Platform.isWindows ? 'Windows-only: ...' : false`

## do NOT

- do NOT revert user's manual edits (CHANGELOG, pubspec, docs). if user touched it, leave it
- do NOT add env vars or flags to work around flaky tests. root-cause or skip
- do NOT add comments unless asked
- do NOT over-explain. short answers. 1-3 lines
- do NOT add tool/ scripts unless needed. if added, keep minimal
- do NOT touch `CHANGELOG.md` after user edits it

## breaking changes

- mark with `**`(Breaking!)`**` in CHANGELOG, like repo does
- bump pubspec version when breaking
- use `%UserProfile%` path notation in CHANGELOG, not `$HOME`

## commits

- NEVER auto-commit. only when user explicitly says "commit" / "commit this" / etc.
- when asked to write commit message: ALWAYS run `git diff` (or `git status --short` + `git diff --staged`) first — do not guess
- message must explain WHY / the goal, not the mechanical WHAT — not "add backslash before $HOME", instead "fix error: unescaped character in path literal"
- if WHY is not obvious from conversation, ASK user: "what's the goal of this edit?" — user describes, you prettify
- conventional: `feat:` `fix:` `refactor:` `test:` `chore:`
- short subject line, blank line, bullet body with what + why

## source rules

- one source of truth — no env override for paths that always default to `~/.inno_bundle/versions`
- `defaultVersion` in `InnoVersionManager` is the only place default Inno version lives
- winget = gone. install via `InnoVersionManager` only
- HELP text must match real behavior, no stale mentions of removed features

## when unsure

- ask. do not assume. better one question than wrong 50 lines