# Development and release

## Local setup

Clone the repository, change to its root and install Lua 5.1 and Python 3. The game loads thirteen Lua files in manifest order and discovers Bindings.xml at the addon root. Use `/reload` for Lua changes. Restart the client if new modules or keybindings are missing.

```bash
for file in ForeverPetModes/*.lua; do luac5.1 -p "$file" || exit 1; done
lua5.1 tests/run.lua
python3 -m unittest discover -s tests
python3 tools/package.py 0.4.1
```

The harness loads modules through the TOC, supplies fixture pet slots and fires events through the addon frame. It checks localization and ranks, manual transitions, partial failure feedback, pre-click slot reordering, missing/dead pets, restricted values, combat guards, profile parsing, persistence and staged settings changes. The harness inspects macro strings. Blizzard's protected execution, actual event delivery and visual rendering require the game.

The packager checks the TOC version, Lua module membership and unique keybinding names. It includes the TOC, referenced Lua modules, Bindings.xml and license under a single addon directory. It reopens the ZIP and checks CRCs, paths and bytes.

## Manual acceptance on Forever

With the panel visible and no hawks active, use `/fpm movehawks`, drag the tab away and release it. Summon a hawk, move or fold the panel, and reload. Check that the tab returns to its chosen spot. Right-click it and open Feed to verify it docks to the picker again.

For the hawk tracker, cast Summon Hawk twice six seconds apart. Compare both countdowns against the native summon icons, then recast with two out. Check an early despawn, Dismiss Pet and a reload with a bird still out. Repeat in combat with the panel visible. Check that automatic or manual sizing, collapse, opening Feed and dragging the resize corner leave the badge legible and the controls accessible. Turn off **Summon Hawk timers**, save and reload to check persistence.

Drag the top gutter with the title shown and hidden. Fold the pet controls and check the margins around the profiles. Click the top-right arrow to reopen. Verify the profiles stay in place and dragging beside the arrow moves the panel. Drag the lower-right grip in both axes at your usual UI scale. Confirm the upper-left stays anchored and skills wrap. Reload, lock the panel, and right-click the unlocked grip to check automatic sizing.

For 0.4.0, switch pets in pinned view, change Growl and compare the panel and minimap tooltip with the native pet bar. Check the following additions with the pet column expanded.

- Move Follow to another pet-bar slot and change that slot’s key. Compare its short label and tooltip with the native button. Send the pet to a hostile target, use Follow, then test Stay. Repeat during combat with the panel visible and check that stance and autocasts retain their settings.
- Watch the health bar as the pet takes damage and receives Mend. Compare with the current and maximum health in the badge tooltip.
- At normal gameplay scale, check that the full name tooltip opens over the badge, health and level fit on one line, and the Follow key clears its caption. Check icon mode, vertical profiles, a partially filled profile row, and collapse with the entire divider strip. Compare compact profile spacing with spacing above 4.
- Bind the left care button. Check the same key and button position for Mend with a living pet, Revive with a dead pet and Call with a dismissed pet. Dismiss the pet with the no-pet filter on. Verify only the named summon card appears, click the portrait to summon, and check that the prior layout returns. Test the care shortcut, a stable swap, a login while dismissed, and a hunter with no remembered pet. Fold and expand before and after a reload and check the outer height. Click Feed (and try the bound key) out of combat. Compare the picker with compatible food in your bags, hover an icon and click it. Verify one piece is consumed and the picker closes. Try duplicate stacks, an empty inventory, moving or locking a stack, changing pets, collapsing the column and entering combat. Check ON/OFF legibility in all three skill display modes at different profile widths. Check a partial last row, a long localized skill name, and the saved choice after reload.
- Right-click Follow, verify its native slot and unbind or rebind a test shortcut. Cancel a conflicting key, then confirm an intentional replacement. Verify the binding survives reload. Right-click a profile and confirm its right-click does not apply the profile.
- Bind a free unmodified key to favorite 3, duplicate a profile, assign it to 3, and apply it with that key outside combat. Reassign and delete the favorite and confirm the old profile no longer fires. Check a separate modified shortcut for a direct command.

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
| Minimap shortcut | Enable the bubble on Panel. Outside combat, left-click to hide and show the panel and right-click for settings. Swap the clicks, save and test both again. Drag on a scaled minimap, save and reload. Check the saved angle, combat click guard, and access with the no-pet filter active. Turn the bubble off and verify /fpm still opens. |
| Show/hide conditions | Check no-pet and combat toggles, enter/leave a dungeon and verify Inside/Outside. Check the deferred instance filter if zoning in lockdown. |
| Drag, lock, change layout and style | Confirm title and outside padding drag, screen clamping, spacing, border, icons, colors and active mark. Verify with title and background hidden. |
| Edit a profile, save, reload, log out and back in | Position, profile rules and appearance survive. Labels and highlights reflect saved rules and the current pet. |
| Named tabs and picker | Set Bite to Leave alone, Turn on and Turn off. Check the saved profile after each choice. A different Growl rank should still match. Change pets with settings open, then save or cancel. |
| Compact indicators and warnings | Check Growl-first order, row wrapping at narrow widths, hover details, icon mode and the checkmark. Verify that combat can show both an active check and an availability warning. |
| Settings validation and reset | Try a bad color, out-of-range size and duplicate spell ID. Cancel preserves current settings. Reset then Save restores defaults. |
| Missing native action or rejected macro line | Read the feedback and apply only the indicated steps via the native bar. State converges without retries. |
| Mouse timing and alternate locale | Repeat the default profile clicks with both action-button key-down settings and a localized Growl name. Check confirmation, sound and taint/error reporting. |

## CurseForge listing

The [project fields, player description and gallery captions](curseforge/listing.md) accompany the original project avatar and the player-provided in-game screenshots. The game ZIP contains only the runtime files and license. The 0.4.0 captures show the expanded control panel, pet details and the food picker. Earlier captures document both selected profiles. The player confirmed that manually toggling Growl clears both profile checkmarks when neither profile matches, and the Growl indicator follows the actual ON/OFF state. The player tested the v0.3.3 minimap preview in-game and approved it for release. Separate in-game results for EnhanceQoL enabled and disabled are still open. [CurseForge submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)

## Publishing

1. Update the TOC version, README release link and changelog.
2. Run syntax, behavior and package checks. Include the live-client status in release notes.
3. Merge to `main`, tag the reviewed commit with `vX.Y.Z`, and push the tag. Checks run on pull requests, main pushes and tags. The tag must match the TOC version.
4. The tag job publishes the ZIP and that version's changelog to GitHub. It verifies the GitHub ZIP checksum and submits the same ZIP and notes to CurseForge project 1826325 as a Release for WoW Forever 1.60.1. CurseForge moderation applies as usual.

The uploader reads the repository Actions secret `CF_API_TOKEN`. When rotating it, generate a CurseForge upload token and replace the encrypted secret in GitHub. Use **Actions → Validate and release → Run workflow** on main to test the saved credential, game version and changelog. This manual run only reads from CurseForge. Run the local uploader tests with `python3 -m unittest discover -s tests`.

GitHub records the returned CurseForge file ID in the ZIP asset label. A rerun skips a completed upload. If the label says **CurseForge upload pending**, check the [project files](https://authors.curseforge.com/#/projects/1826325/files) for that exact ZIP before retrying. If CurseForge already has it, use GitHub's release editor to set the asset label to `ForeverPetModes-vX.Y.Z.zip (CurseForge file ID)`, substituting the version and numeric file ID. If the upload definitely failed before acceptance, clear the label and rerun the failed job. A checksum mismatch requires investigating the existing GitHub release before continuing. To turn off CurseForge publishing, remove the submission step from the workflow and revoke its upload token.

Code contributions should keep the profile list data-driven and preserve the click boundary documented in [ADR 0001](adr/0001-forever-secure-actions.md).
