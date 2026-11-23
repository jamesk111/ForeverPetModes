# Development and release

## Local setup

Clone the repository, change to its root and install Lua 5.1 and Python 3. There are no Lua libraries, Python packages or daemons to configure. The game loads the eight source files in manifest order. Changes to Lua can normally be loaded with `/reload`. Restart the client after adding a module or changing the manifest if the new files are missing.

```bash
for file in ForeverPetModes/*.lua; do luac5.1 -p "$file" || exit 1; done
lua5.1 tests/run.lua
python3 tools/package.py 0.2.0
```

The harness loads modules through the TOC, supplies fixture pet slots and fires events through the addon frame. It checks localization and ranks, manual transitions, partial failure feedback, pre-click slot reordering, missing/dead pets, restricted values, combat guards, profile parsing, persistence and staged settings changes. The harness inspects macro strings. Blizzard's protected execution, actual event delivery and visual rendering require the game.

The packager reads the manifest version, checks module membership and writes only the TOC, referenced Lua and license under a single addon directory. It reopens the ZIP, checks CRCs, paths and bytes. The ZIP excludes test fixtures, docs and local client data.

## Manual acceptance on Forever

**Status for v0.2.0:** live verification of the updated panel is pending. Record build, locale, pet and outcomes when running this checklist. Use a player-controlled game session with the default pet bar.

| Scenario | Expected result |
| --- | --- |
| Clean login with addon enabled | No Lua errors. Two buttons appear; labels fit. `/fpm status` reports the expected build and TOC. |
| Live hunter pet with Defensive, Passive and Growl on its bar | Click Solo, then Dungeon. Inspect the native selected stance and autocast border after each click. Green/blue and the checkmark appear only on the full match. Repeating either click leaves the native setting stable. |
| Dungeon to Solo with a delayed Growl update | During the switch, the old blue mark clears. Check the live stance and Growl row against the native bar. Solo turns green when Defensive and Growl ON are both observed. Check with the pointer over each button. |
| Manually change only stance or only Growl | A partial match immediately loses its highlight. Completing the other profile activates it without clicking the addon. |
| Move stance and Growl to other slots; use another pet or a different Growl rank | A fresh click resolves the new slots and localized name. No unrelated ability is activated. |
| Dismiss, summon, kill and revive pet | Active marks clear and return with readable matching state. Removing a required ability shows an amber warning. Restoring it clears the warning. |
| Start combat, swap or lose pet, then leave combat | No automatic pet commands, blocked-action errors or stale matches. Hovering the warning shows the combat restriction. On leaving combat, bindings update and a new click is required. |
| Show/hide conditions | Check no-pet and combat toggles, enter/leave a dungeon and verify Inside/Outside. Check the deferred instance filter if zoning in lockdown. |
| Drag, lock, change layout and style | Confirm title and outside padding drag, screen clamping, spacing, border, icons, colors and active mark. Verify with title and background hidden. |
| Edit a profile, save, reload, log out and back in | Position, profile rules and appearance survive. Labels and highlights reflect saved rules and the current pet. |
| Named tabs and picker | Set Bite to Leave alone, Turn on and Turn off. Check the saved profile after each choice. A different Growl rank should still match. Change pets with settings open, then save or cancel. |
| Compact indicators and warnings | Check Growl-first order, row wrapping at narrow widths, hover details, icon mode and the checkmark. Verify that combat can show both an active check and an availability warning. |
| Settings validation and reset | Try a bad color, out-of-range size and duplicate spell ID. Cancel preserves current settings. Reset then Save restores defaults. |
| Missing native action or rejected macro line | Read the feedback and apply only the indicated steps via the native bar. State converges without retries. |
| Mouse timing and alternate locale | Repeat the default profile clicks with both action-button key-down settings and a localized Growl name. Check confirmation, sound and taint/error reporting. |

## Publishing

1. Update the TOC version, README release link and changelog.
2. Run syntax, behavior and package checks. Include the live-client status in release notes.
3. Merge to `main`, tag the reviewed commit with `vX.Y.Z`, and push the tag. Checks run on pull requests, main pushes and tags. The tag must match the TOC version.
4. The tag job publishes the tested ZIP as a GitHub release asset. Download it, inspect its single top-level directory and verify the artifact against the local build. A release rerun replaces the asset for that tag.

Code contributions should keep the profile list data-driven and preserve the click boundary documented in [ADR 0001](adr/0001-forever-secure-actions.md).
