# Project Zomboid: API check for the Cyrus generator (2026-10-08)

Every Java method the generator emits was checked against the **42.21 JavaDocs** (albion.codeberg.page/PZ-JavaDocs, "PZ API Documentation 42.21.0"), every vanilla Lua function against the **42.20.3 LuaDocs** (demiurgequantified.github.io/ProjectZomboidLuaDocs) and the **Umbrella** typings (github.com/PZ-Umbrella/Umbrella, last commit 2026-09-28), and every script/translation format against **The Indie Stone's own migration guides** for 42.13 and 42.15 and the **PZ API Docs** script reference (generated from 42.21). The old handoff generator had no `plausible:` tags, but it was written against early Build 42 and several of its calls no longer exist.

Note on sources: early in this session I fetched a few pzwiki.net pages as raw wikitext with `curl` (WebFetch got a 403). The coordinator then said pzwiki is behind Cloudflare and must not be bypassed. I stopped, and every fact in the shipped files is now sourced from the primary sources above; pzwiki is not cited anywhere.

## Removed or wrong in the old generator (fixed)

| Old call / format | Status in 42.21 | Replacement |
|---|---|---|
| `getStats():getFatigue()/setFatigue()`, `getEndurance/setEndurance`, `getPanic/setPanic` | Gone (Stats has only `get/set/add(CharacterStat, …)`) | `getStats():add(CharacterStat.X, delta)` via a guarded `nudge()` helper |
| `getBodyDamage():getPoisonLevel()/setPoisonLevel()`, `getTemperature()/setTemperature()` | Gone from BodyDamage | `CharacterStat.POISON`, `CharacterStat.TEMPERATURE` |
| `IsoPlayer:setRunSpeedModifier()` | Does not exist | "second wind": endurance up, fatigue down |
| `getMoodles():getNumMoodles()` | Does not exist | HUD shows `CharacterStat.STRESS` |
| `who:setLx()/setLy()` | Do not exist (`setLastX/setLastY`) | `character:teleportTo(x, y, z)`; on a dedicated server the blink becomes a stamina burst (no client teleports) |
| `square:Is(IsoFlagType.water)` | `Is` gone; `has(IsoFlagType)` / `isWaterSquare()` | `square:isWaterSquare()` |
| `OnWeaponHitCharacter` for zombie hits | Sources disagree on whether zombies fire it | `OnHitZombie(zombie, attacker, bodyPart, weapon)` |
| Item `Type = Weapon`, `DisplayName = …` | Removed in 42.13 | `ItemType = base:weapon`, name in `ItemName.json` |
| Weapon `Categories = Axe/Blunt` | Registry ids since 42.13 | `base:axe` / `base:blunt` (WeaponCategory fields AXE, BLUNT…) |
| Recipe `tags[Screwdriver]` | Registry ids since 42.13 | `tags[base:screwdriver]` (ItemTag doc lists it) |
| `IG_UI_EN.txt`, `Sandbox_EN.txt` Lua tables | Not loaded since 42.15 | `IG_UI.json`, `Sandbox.json` (+ `ItemName.json`, `Recipes.json`, `Mod.json`) |
| Timed actions in `lua/client`, items changed client side | Broken in 42.13+ MP | `lua/shared/<Mod>/Actions.lua`, `getDuration()`, `complete()` with `UseAndSync`, `syncItemFields`, `instanceItem` + `sendAddItemToContainer` / `sendRemoveItemFromContainer` |
| Quest reward `player:getXp():AddXP`, `AddItem` on the client | Anti-cheat / deleted on relog | server command → `addXp(player, Perks.X, n)` + server-side item |
| Trade action `new(character, npc, cost)` | Field names must equal arg names; price must not come from the client | `new(character)`, price computed in `complete()` |
| `sendServerCommand` to drive client UI in singleplayer | OnServerCommand is multiplayer-only; sendServerCommand does nothing on a client | `notify()` helper: `sendServerCommand` on a server, `triggerEvent("OnServerCommand", …)` otherwise |
| `42/media/maps/<Mod>/spawnpoints.lua` + `map.info` with `lots=Muldraugh, KY` | Untested half-map; risks a broken map entry | dropped; the world archetype is Lua-only (zone + loot + anomalies) |
| `getWorld():registerZone(...)` on map load | Exists, but adds an unknown zone type for no gameplay value | dropped |
| `module Base` for items | Clashes with vanilla ids | own module (`module <ModId> { imports { Base } }`) |
| mod.info `poster=poster.png`, `icon=icon.png` with no files | Mod manager shows no image | omitted until art exists; listed in ASSETS.md |

## Verified present in 42.21 (used as is)

IsoZombie: setWalkType, setUseless, setNoTeeth, setTarget, getTarget, getOutfitName, getOnlineID; IsoGameCharacter: Kill(IsoGameCharacter), setHealth/getHealth, setInvincible, pathToSound(int,int,int), getPersistentOutfitID, Say, setHaloNote(String,int,int,int,float), faceThisObject, getXp, isEquipped, getClothingItem_Back, getZombieKills, isSprinting, isRunning, setMetabolicTarget, getForwardDirection, getMoodles, teleportTo, getPrimaryHandItem, getVehicle; IsoPlayer: isLocalPlayer, getPlayerNum, isTimedActionInstant, shouldBeTurning, getUsername; BodyDamage: AddGeneralHealth, getOverallBodyHealth; Stats: get/set/add(CharacterStat); CharacterStat fields incl. FATIGUE ENDURANCE PANIC POISON STRESS TEMPERATURE, getMinimumValue/getMaximumValue; IsoGridSquare: haveFire, getMovingObjects, isFree(boolean), isOutside, isWaterSquare, getBuilding; IsoFireManager.StartFire(IsoCell, IsoGridSquare, boolean, int); ThunderStorm.triggerThunderEvent(int,int,bool,bool,bool); ClimateManager: getThunderStorm, getTemperature, getPrecipitationIntensity, getFogIntensity, getClimateFloat(int), getClimateColor(int), FLOAT_DESATURATION, FLOAT_FOG_INTENSITY, FLOAT_GLOBAL_LIGHT_INTENSITY, COLOR_GLOBAL_LIGHT; ClimateFloat: setEnableModded, setModdedValue, setModdedInterpolate; ClimateColorInfo(8 floats); WorldSoundManager.addSound(Object,int,int,int,int,int); GameTime: getHour, getMinutes, getWorldAgeHours, getNightsSurvived, getTimeOfDay, getRealworldSecondsSinceLastUpdate; ItemContainer: getItems, AddItem(InventoryItem), getCountTypeRecurse, getFirstTypeRecurse, containsTypeRecurse, contains, hasRoomFor, Remove; InventoryItem: getFullType, getCondition, getConditionMax, setCondition, isBroken, UseAndSync, setJobDelta, setJobType, getCategory, isFavorite, getContainer; InventoryContainer.getItemContainer; BaseVehicle: isDriver, isEngineRunning, getCurrentSpeedKmHour, getScriptName, getPartById, setEngineFeature(int,int,int), getEnginePower, getEngineQuality, getEngineLoudness; ModData: getOrCreate, transmit, request, add; SoundManager: PlayWorldSound(String, IsoGridSquare, float, float, float, boolean), PlaySound(String, boolean, float) → Audio, playUISound; IsoUtils.DistanceTo; TextManager.getFontHeight; SafeHouse.getSafeHouse(IsoGridSquare); PerkFactory.Perks Doctor/Maintenance/Strength/MetalWelding/Electricity; Metabolics.LightWork; CharacterActionAnims.Craft; IsoFlagType.water.

Globals (LuaManager.GlobalObject): addZombiesInOutfit(x,y,z,n,outfit,femaleChance) → ArrayList<IsoZombie>, getCell, getClimateManager, getWorldSoundManager, getGameTime, getOnlinePlayers, getNumActivePlayers, getSpecificPlayer, ZombRand, ZombRandFloat, getTimestampMs, sendClientCommand(player, …), sendServerCommand([player,] …), getTextOrNull, getItemNameFromFullType, AddWorldSound, getSoundManager, isClient, isServer, getPlayerScreenLeft/Top/Width, getTextManager, isDebugEnabled, instanceItem(String), sendAddItemToContainer, sendRemoveItemFromContainer, addXp(IsoPlayer, Perk, float), syncItemFields(IsoPlayer, InventoryItem), triggerEvent(String, …), require(String) → Object.

Vanilla Lua (LuaDocs/Umbrella): ISBaseTimedAction (shared/TimedActions) derive/perform/getDuration/stop/setActionAnim/setOverrideHandModels/isValid/waitToStart/update/start/getJobDelta; ISTimedActionQueue.add/isPlayerDoingAction/getTimedActionQueue; ISInventoryPaneContextMenu.transferIfNeeded/addToolTip; luautils.walkAdj; ISContextMenu getNew/addOption/addSubMenu; ISCollapsableWindow createChildren/titleBarHeight/close; ISRichTextPanel paginate/addScrollBars; ISPanel prerender/render/drawText/drawTextRight/drawRect; ISInventoryTransferAction:new; PZAPI.ModOptions:create(id,name) → addKeyBind/addTickBox/getOption():getValue(); ProceduralDistributions.list (server/Items); VehicleZoneDistribution (shared). Events (Umbrella): OnHitZombie, OnZombieUpdate (client), OnPlayerUpdate (client), OnExitVehicle (client), OnZombieDead, OnPreDistributionMerge, OnFillInventoryObjectContextMenu, OnFillWorldObjectContextMenu, OnClientCommand (server), OnServerCommand (MP client), OnReceiveGlobalModData (MP), EveryHours, EveryTenMinutes, EveryOneMinute.

## Still unverified (also in the GameSupport `unknowns`)

- `CharacterStat` reachable as a Lua global (guarded with `if CharacterStat`).
- Server-side stat/health changes reaching the client screen immediately in MP.
- Server-side `setWalkType` mirrored to clients.
- Client-only ClimateManager overrides surviving the server's climate sync.
- `triggerEvent("OnServerCommand", …)` in singleplayer.
- `fmod.fmod.Audio:setVolume/stop` (class not in the zombie JavaDocs; used by vanilla).
- Vanilla crafting category names other than the documented default `Miscellaneous`.
