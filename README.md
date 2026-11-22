# Forever Pet Modes

Switch a hunter pet between solo and dungeon settings in **World of Warcraft: Forever**. The panel reads the pet action bar after a click and when the game reports changes. An asterisk and the profile color mark a complete match.

| Button | Pet stance | Growl autocast | Active appearance |
| --- | --- | --- | --- |
| Solo Mode | Defensive | On | Green with an asterisk |
| Dungeon Mode | Passive | Off | Blue with an asterisk |

**Panel example** with Defensive selected and Growl on

```text
┌────────── Forever Pet Modes ──────────┐
│ [ Solo Mode  * ]   [ Dungeon Mode  ] │
└───────────────────────────────────────┘
```

Turn off Growl on the pet bar while still in Defensive and both buttons lose their highlight. Select Passive and Dungeon lights up. If you configure two identical profiles, both highlight when their rules match.

## Install v0.1.0

1. Download **ForeverPetModes-v0.1.0.zip** from the [release](https://github.com/jamesk111/ForeverPetModes/releases/tag/v0.1.0).
2. Close WoW and extract the ZIP into `World of Warcraft/_forever_/Interface/AddOns/`. The resulting file path should end in `AddOns/ForeverPetModes/ForeverPetModes.toc`.
3. Start Forever, enable **Forever Pet Modes** in the AddOns list and log in. Summon a pet. Place its stance controls and Growl on the Blizzard pet action bar.
4. Click a profile with the left mouse button and no modifier keys, outside combat. Hover for missing steps. Type `/fpm status` to inspect the current stance, spell IDs, autocast values and profile matches.

Target client **1.60.1**, interface **16001**. The UI implementation was checked against build **71037**. Lua and release packaging were tested offline. Live-client acceptance is pending, including native macro execution, taint checks and persistence across an actual logout.

## Configure the panel

Type **`/fpm`** outside combat. Use the arrows to move between Appearance, Behavior and each profile. **Save** applies all pages together. **Cancel** or Escape discards the draft. **Reset to defaults** stages the original position and both default profiles for review before saving.

| Page | Controls |
| --- | --- |
| Appearance | Width, height, scale, spacing, border, inactive hex color, vertical or horizontal layout, icon or text buttons, title visibility, background opacity |
| Behavior | Lock position, hide without a pet, hide in combat, show anywhere or only inside/outside instances, optional chat and sound confirmation |
| Each profile | Button label, active hex color, icon file ID, stance and ability autocast rules |

Drag the title or outer padding to position the panel. The padding still works with the title hidden. Set background opacity to `0` for a transparent panel. Position and settings are account-wide and saved by WoW on a normal logout or `/reload`.

Ability rules use a comma-separated list such as `2649=on, 17253=off`. Use `/fpm status` for IDs on your current pet. Leave the field empty to manage stance alone. A rule can match another rank by the localized name of its configured spell ID. An ability must support autocast and be present on the pet bar. Put the corresponding ability there or edit the profile if you change pets.

## Clicks and combat

The addon builds an out-of-combat click from the current stance slot and the localized names of the required abilities. It requests explicit autocast on or off, so repeating a click preserves the intended setting. It checks the entire configuration before binding a button. If a required ability or stance is missing, the click explains what to place on the bar.

If the client accepts only part of a click, the addon reads the result. Its message tells you which stance to select or which spell to right-click. In combat, use the Blizzard pet bar. Highlighting continues when readable, and unavailable or restricted data clears the highlight. Zoning and leaving combat refresh visibility and bindings. All pet actions require a fresh player click.

## Architecture

The TOC loads seven Lua modules into a shared addon-private namespace. Defaults supplies configuration data. PetState reads the game's current pet bar. Profiles compares that snapshot against each profile. SecureActions binds hardware clicks and verifies their results. UI draws and moves the panel. Settings validates draft edits and saved values. Core handles the addon lifecycle and coalesces event-driven refreshes. The ordered profile list drives button creation, settings pages and matching.

The compatibility research, Blizzard policy review and design tradeoffs are in [ADR 0001](docs/adr/0001-forever-secure-actions.md). The [development guide](docs/development.md) covers tests, packaging, manual acceptance and publishing.

## Run checks and build a ZIP

From the repository root with Lua 5.1 and Python 3 installed, run

```bash
lua5.1 tests/run.lua
python3 tools/package.py 0.1.0
```

The install package is written to `dist/ForeverPetModes-v0.1.0.zip`. There are no runtime dependencies beyond the game client.

## Troubleshooting and shutdown

- **Missing from the AddOns list.** Check the Forever folder and exact TOC path above. Fully restart the client after adding a new addon. Compare the installed interface using `/run print(select(4, GetBuildInfo()))`.
- **Panel missing.** Open `/fpm`, check no-pet, combat and instance visibility, or stage a reset and save.
- **Gray buttons.** Read `/fpm status`. A dead or missing pet, unavailable ability, partial match or restricted value can leave both inactive. Add the missing stance or spell to the native bar. Unknown stances remain unmatched.
- **Stance failed to change.** Select it on the Blizzard pet bar. If an autocast rule also differs, right-click the indicated ability there. Status should update after the native event. If another addon replaces the bar, reproduce with the default UI.
- **Disable or remove.** Disable Forever Pet Modes in the AddOns list and reload, or exit the game and remove its addon folder. Reset and save in `/fpm` first if you want the account settings returned to defaults.

Forever Pet Modes is free and distributed under the [MIT license](LICENSE).
