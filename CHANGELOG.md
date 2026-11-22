# Changelog

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
