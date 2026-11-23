# Development and release

## Local setup

Clone the repository, change to its root and install Lua 5.1 and Python 3. There are no Lua libraries, Python packages or daemons to configure. The game loads the nine source files in manifest order. Changes to Lua can normally be loaded with `/reload`. Restart the client after adding a module or changing the manifest if the new files are missing.

```bash
for file in ForeverPetModes/*.lua; do luac5.1 -p "$file" || exit 1; done
lua5.1 tests/run.lua
python3 tools/package.py 0.3.2
```

The harness loads modules through the TOC, supplies fixture pet slots and fires events through the addon frame. It checks localization and ranks, manual transitions, partial failure feedback, pre-click slot reordering, missing/dead pets, restricted values, combat guards, profile parsing, persistence and staged settings changes. The harness inspects macro strings. Blizzard's protected execution, actual event delivery and visual rendering require the game.

The packager reads the manifest version, checks module membership and writes only the TOC, referenced Lua and license under a single addon directory. It reopens the ZIP, checks CRCs, paths and bytes. The ZIP excludes test fixtures, docs and local client data.

## Manual acceptance on Forever

**Status for v0.3.2:** live verification of the updated panel is pending. Record build, locale, pet and outcomes when running this checklist. Use a player-controlled game session with the default pet bar.

| Scenario | Expected result |
| --- | --- |
| Clean login with addon enabled | No Lua errors. Two buttons appear; labels fit. `/fpm status` reports the expected build and TOC. |
| Live hunter pet with Defensive, Passive and Growl on its bar | Click Solo, then Dungeon. Inspect the native selected stance and autocast border after each click. Green/blue and the checkmark appear only on the full match. Repeating either click leaves the native setting stable. |
| Dungeon to Solo with a delayed Growl update | During the switch, the old blue mark clears. Check the live stance and Growl row against the native bar. Solo turns green when Defensive and Growl ON are both observed. Check with the pointer over each button. |
| Manually change only stance or only Growl | A partial match immediately loses its highlight. Completing the other profile activates it without clicking the addon. |
| Move stance and Growl to other slots; use another pet or a different Growl rank | A fresh click resolves the new slots and localized name. No unrelated ability is activated. |
| Dismiss, summon, kill and revive pet | Active marks clear and return with readable matching state. Removing a required ability shows an amber warning. Restoring it clears the warning. |
| Start combat, swap or lose pet, then leave combat | No automatic pet commands, blocked-action errors or stale matches. Hovering the warning shows the combat restriction. On leaving combat, bindings update and a new click is required. |
| Hunter visibility and upgrade | Log in on a Hunter and a Warlock with a pet. The panel appears only on the Hunter by default. From the Warlock, open /fpm, disable Hunters only and save. Restore it and verify both surfaces hide again. |
| Minimap button bin | With EnhanceQoL’s bin enabled, turn the FPM launcher on after login. Open the bin, click the icon, save settings, enter and leave combat, and reload. Check that one icon stays grouped. Turn the launcher off and on. With the bin disabled verify independent placement and drag. |
| Minimap shortcut | Enable the bubble on Panel. Open settings with a click, drag on a scaled minimap, save and reload. Check the saved angle, combat click guard, and access with the no-pet filter active. Turn the bubble off and verify /fpm still opens. |
| Show/hide conditions | Check no-pet and combat toggles, enter/leave a dungeon and verify Inside/Outside. Check the deferred instance filter if zoning in lockdown. |
| Drag, lock, change layout and style | Confirm title and outside padding drag, screen clamping, spacing, border, icons, colors and active mark. Verify with title and background hidden. |
| Edit a profile, save, reload, log out and back in | Position, profile rules and appearance survive. Labels and highlights reflect saved rules and the current pet. |
| Named tabs and picker | Set Bite to Leave alone, Turn on and Turn off. Check the saved profile after each choice. A different Growl rank should still match. Change pets with settings open, then save or cancel. |
| Compact indicators and warnings | Check Growl-first order, row wrapping at narrow widths, hover details, icon mode and the checkmark. Verify that combat can show both an active check and an availability warning. |
| Settings validation and reset | Try a bad color, out-of-range size and duplicate spell ID. Cancel preserves current settings. Reset then Save restores defaults. |
| Missing native action or rejected macro line | Read the feedback and apply only the indicated steps via the native bar. State converges without retries. |
| Mouse timing and alternate locale | Repeat the default profile clicks with both action-button key-down settings and a localized Growl name. Check confirmation, sound and taint/error reporting. |

## CurseForge listing

The [project fields, player description and gallery captions](curseforge/listing.md) accompany the original project avatar and the two player-provided in-game screenshots. The game ZIP contains only the runtime files and license. The captures document both selected profiles. The manual Growl override and launcher behavior with and without EnhanceQoL still need player confirmation for the planned Release submission. [CurseForge submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)

## Publishing

1. Update the TOC version, README release link and changelog.
2. Run syntax, behavior and package checks. Include the live-client status in release notes.
3. Merge to `main`, tag the reviewed commit with `vX.Y.Z`, and push the tag. Checks run on pull requests, main pushes and tags. The tag must match the TOC version.
4. The tag job publishes the tested ZIP as a GitHub release asset. Download it, inspect its single top-level directory and verify the artifact against the local build. A release rerun replaces the asset for that tag.

Code contributions should keep the profile list data-driven and preserve the click boundary documented in [ADR 0001](adr/0001-forever-secure-actions.md).
