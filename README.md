# piercer_clothslot

[Português (BR)](README.pt-BR.md)

Shows in real time the GTA V global slot, `addon` collection, local drawable number and exact disk folder for every
clothing item worn by your character, and lets you search folders by name and try items on right away. It has an
**in-game NUI** (`/clothslot` or `/roupaslot`), an **on-screen HUD** (`/roupaslot painel`) and chat/F8 subcommands.
The NUI is available in **English and Portuguese (BR)**.

## Installation

```cfg
ensure vrp
ensure framezero_bridge
ensure piercer_clothslot
```

In-game permission: groups in `Config.permissoesBridge` (via `framezero_bridge`), `Config.permissao` in vRP, or ACE
(`add_ace group.admin piercer.admin allow`). Works with freemode peds (`mp_m_freemode_01` and `mp_f_freemode_01`).

## Language

- Use the `PT / EN` selector at the top of the NUI to switch languages; the choice is remembered in that browser.
- NUI texts live in `I18N` inside `web/app.js`; chat, F8 and on-screen HUD messages live in `Config.textos` (`config.lua`).

## What it does

| Feature | How to use | Notes |
|---|---|---|
| **Equipped inspector** | **Equipped Clothes** tab, `/roupaslot atual` or `/roupaslot painel` | Reads components `0` to `11` (`jbib`, `lowr`, `feet`, `berd`, `accs`...), resolves each global slot back to its collection + local index, and matches `data/index.lua` to show the disk folder. |
| **Folder search** | **Search Clothes** tab or `/roupaslot buscar <text>` | Searches the index by folder name (up to 60 results), resolves the live global slot on the client, and lets you **Wear** it immediately or copy the slot. |
| **Loaded collections** | **Loaded Collections** tab or `/roupaslot colecoes` | Lists every active `addon` pack on the ped, its piece count, and the global slot range it occupies. |
| **Forward / reverse lookup** | `/roupaslot <collection> <piece> <num>` and `/roupaslot slot <piece> <slot>` | Converts between `collection + local number` (e.g. `addon5 jbib 51`) and `global slot` (e.g. `slot jbib 500`) straight from chat. |
| **Try on & cycle** | `/roupaslot vestir <collection> <piece> <num> [tex]`, `PageDown` / `PageUp` | After putting an item on (via NUI or command), `PageDown` and `PageUp` step forward or backward through that same collection. Keys can be rebound in FiveM settings. |
| **Full dump** | **Generate Dump** button in the NUI | Streams all clothes on the current ped in chunks (`TriggerLatentServerEvent`), saves `data/dump_<model>.txt`, and reports what was added, removed or resized since the previous dump. |

## Folder index (`tools/`)

FiveM only knows `collection + component + number`, never the original Windows folder name. `data/index.lua` bridges
the two and is built outside the game with the included PowerShell scripts:

- **Rebuild the index**: whenever you add, remove or rename folders in `stream`, run:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools/gerar_indice.ps1
  ```
  By default it scans `[framezero-cloth]/style-cloth-addon/stream` (accepts `-Stream "<path>"` and `-Saida "<file>"`). Restart `piercer_clothslot` afterwards.
- **Gaps in numbering**: if a collection skips numbers (e.g. has `000` and `002`, missing `001`), the in-game slot can shift relative to the `.ydd` filename. The generator flags that group under `duvidosos` and the HUD appends `(!)` so you know to double-check the folder.
- **Stream audit**: `tools/analisar_pastas.ps1` (accepts `-Cloth "<path>"`) writes `data/relatorio_roupas.csv` and prints missing sequence numbers, drawables without `.ytd` textures, and `addon` folders missing a `.meta` file.

## Settings

- `config.lua`: commands (`/clothslot`, `/roupaslot`), permissions, dump transfer rate (`velocidadeEnvio`), default cycle keys (`PAGEDOWN`/`PAGEUP`), on-screen HUD position/interval (`painel`), allowed ped models, `0–11` component map and chat/HUD messages.
