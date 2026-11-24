# Changelog

## v0.3.3 · 2026-11-24

- Outside combat, left-click the minimap button to hide or show the Solo/Dungeon panel. Right-click opens settings.
- To swap the clicks, open /fpm, go to **Panel**, change **Show/hide panel with** to **Right-click**, and save. You can enable the optional **Minimap button** on the same tab.
- The panel remembers a manual hide across reloads. Showing it restores your usual visibility rules. The minimap controls were tested in-game before release.

## v0.3.2 · 2026-11-23

- Display the installed addon version beside the title in the settings window.
- Added CurseForge listing materials and in-game screenshots of both default modes.

## v0.3.1 · 2026-11-23

- Register the optional minimap button with the shared launcher libraries used by EnhanceQoL’s button bin.
- Leave positioning to the collector while grouped. Retain standalone behavior and saved settings for installations without the libraries.

## v0.3.0 · 2026-11-23

- Show the panel only on Hunters by default. The account-wide setting can be changed from any class with /fpm.
- Added an optional draggable minimap settings button. It follows the class filter, remembers its position, and remains accessible when the main panel is hidden by its pet or instance filters.

## v0.2.0 · 2026-11-23

- Added a checkmark for a full profile match and an amber availability marker with hover details.
- Put Growl first in the compact autocast row. Hover an ability to see how each profile treats it.
- Replaced settings paging with named tabs and added a three-choice picker for pet abilities. Advanced retains color, icon and raw-rule controls.
- Recheck the native stance target and pet at click time, discard stale confirmation callbacks on pet changes and shorten oversized macros when some settings already match.

## v0.1.2 · 2026-11-21

- Recognize the Forever pet button labeled Defensive, including its DefensiveAssist token. This restores the Solo binding and its Growl ON command on affected pet bars.
- Keep click feedback on the profile buttons. The panel shows current pet state and ability flags. Troubleshooting details are available on hover.

## v0.1.1 · 2026-11-21

- Added live stance and autocast indicators beneath the buttons, including unavailable configured abilities.
- Moved click feedback onto the panel. Hover previews the profile's requested settings.
- Clear the previous highlight during a switch and recheck delayed pet-bar updates. A superseded click cannot overwrite the latest result.
- Treat numeric zero as an inactive pet-bar flag. Added regression tests for the Dungeon-to-Solo transition.

## v0.1.0 · 2026-11-21

- Added Solo and Dungeon profiles with exact pet-bar matching and manual fallback feedback.
- Added a movable panel with saved appearance, visibility, position and profile rules.
- Added in-game settings, a pet-status command, Lua fixture tests and automated release packaging.
- Targeted Forever 1.60.1, interface 16001. The native UI source was reviewed at build 71037. Live-client acceptance is pending.
