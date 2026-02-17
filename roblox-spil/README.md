# Monkey Canopy Dash (Roblox MVP)

Dette er et **MVP-starterkit** i Lua til Roblox Studio med temaet **Monkey Canopy Dash**.

## Features (MVP)
- Abe-look (R15 + simpel "MonkeyHat" accessory på character spawn).
- Trætops-hub + obby-run i canopy.
- Swing points (vine swing) via `ContextActionService` (PC + mobil).
- Collectibles med `CollectionService` tags:
  - `BananaCrystal` (coins)
  - `LeafToken` (skill points)
- Finish zone med server-authoritative belønning (tid + collectibles).
- HUD med coins, level, tokens, run timer.
- XP/level progression + gate til næste område ved level 5.
- DataStore save/load: coins, xp, level, unlocked skills.
- Debounce på pickups.

---

## Explorer struktur (placer scripts sådan)

```text
ReplicatedStorage
└── Modules
    ├── Config.lua
    ├── Remotes.lua
    └── PlayerData.lua

ServerScriptService
├── DataService.lua
├── RunService.lua
└── Collectibles.lua

StarterPlayer
└── StarterPlayerScripts
    ├── UI.client.lua
    ├── Input.client.lua
    └── Effects.client.lua
```

---

## CollectionService tags du skal sætte i Studio
Brug **Tag Editor** plugin eller `CollectionService:AddTag` i command bar.

- `BananaCrystal` på coin Parts
- `LeafToken` på token Parts
- `FinishZone` på målzonen (Part)
- `SwingPoint` på faste swing points (Part/Attachment-holder)
- `LevelGate` på gate-parten til area 2

---

## Hurtig opsætning
1. Opret et nyt Baseplate spil.
2. Lav canopy-bane (platforms, ziplines som visuals, swing points).
3. Tilføj tags ovenfor.
4. Indsæt scripts i de viste placeringer.
5. Tryk **Play**.
6. Start run med `R` (eller mobil-knap). Swing med `E` (eller mobil-knap).

---

## Noter
- Ziplines i denne MVP er primært level-geo/visual + movement via swing system.
- `RunService.lua` validerer finish server-side.
- `Collectibles.lua` håndterer pickup debounce server-side.
- `DataService.lua` gemmer progression i DataStore.
