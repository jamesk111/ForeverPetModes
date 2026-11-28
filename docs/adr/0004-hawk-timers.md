# ADR 0004 · Dock Summon Hawk timers to the panel edge

## Decision

The first preview put the timers inside the resize gutter. Player feedback showed the skill row and timers looked crowded together. Dock a 126 × 28 tab three units below the panel, aligned to its left edge. The spell icon and count occupy the left side. Two equal-width timer slots show seconds and a shrinking line. The soonest expiry appears first and turns amber for its last three seconds. A vacant slot stays dim, keeping the tab steady as the number of hawks changes.

By default the tab follows the food picker when open and flips above the panel if the screen has insufficient room below. The Call Pet card uses the same design. Each tab remains a child of its display surface for visibility. Dragging the tab changes its anchor to the screen. The two surfaces share one account-wide position, recorded as fractions of screen width and height so the same location can be restored across interface scales. Right-click restores automatic docking. An explicit placement command shows both empty timer slots so adjusting the tab costs no mana.

## Timing and limits

Read the hunter’s summon slots on world entry, after combat and on summon updates. A matching spell ID, localized spell name or spell icon identifies a hawk. Readable slot updates replace cast estimates and remove birds that despawn early. A successful player cast of a Summon Hawk rank can supply an 18-second estimate when slot information is unavailable. Coalesce cast and slot notifications in either order. Count at most two birds. Reset on player death or a successful Dismiss Pet.

The Forever API marks some combat data as secret. Check values before comparing or formatting them. The badge marks estimates with a tilde. When neither a cast nor its summon is identifiable, the tracker has no evidence to add a timer. Timeouts refresh only while tracking birds. [Forever slot API](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/TotemDocumentation.lua) · [Forever unit events](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua) · [In-game tracking observations](https://www.curseforge.com/wow/addons/summon-hawk-tracker)
