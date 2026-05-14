# Pizza_libs

Delte bibliotek til **alle** dine scripts (notify, text UI, progressbar, 3D-interaktion, blips m.m.) med ét **NUI** i `pizza_libs`-ressourcen — samme idé som [st_libs](https://github.com/Stausi/st_libs): ét startet lib-resource, andre ressourcer loader `init.lua` og bruger `pizza` / `lib`.

## Krav

- **Lua 5.4** (`lua54 'yes'` i begge manifests).
- `pizza_libs` skal starte **før** scripts der bruger det (sæt den tidligt i `server.cfg`).

## Brug i et andet script

**1.** Tilføj afhængighed i dit scripts `fxmanifest.lua`:

```lua
dependency 'pizza_libs' -- eller: dependencies { 'pizza_libs', }
```

**2.** Tilføj initiator som shared script (som `@st_libs/init.lua`):

```lua
shared_scripts {
    '@pizza_libs/init.lua',
}
```

**3.** (Valgfrit) Forudindlæs moduler via metadata-nøglerne **`pizza_lib`** eller **`pizza_libs`** (samme rolle som `st_lib` hos [st_libs](https://github.com/Stausi/st_libs)) — afhængigt af hvad din fxmanifest-parser accepterer, fx:

```lua
pizza_lib 'notify'
pizza_lib 'print'
```

eller, hvis jeres miljø understøtter tabel-syntaks:

```lua
pizza_libs {
    'notify',
    'print',
    'progressbar',
}
```

Hvis du udelader blokken, indlæses moduler stadig **lazy** første gang du kalder fx `pizza.notify(...)` eller `lib.showTextUI(...)`.

**4.** I Lua bruger du `pizza` eller aliaset `lib` (samme tabel):

```lua
-- Client
lib.notify({ title = 'Hej', type = 'success' })
lib.ready(function()
    lib.showTextUI('Tryk [E]')
end)

-- Server (notifikationer til én spiller — event er scoped til dit resource-navn)
lib.notify(playerId, { title = 'Server', description = 'Besked' })
```

Brug **ikke** længere det globale eventnavn `pizza_libs:notify` fra egne ressourcer; brug `lib.notify(playerId, data)` på serveren, så klienten får det rigtige interne event.

## Globale felter

| Navn    | Betydning                                      |
|---------|------------------------------------------------|
| `pizza` | Hoved-API (lazy modules + exports)             |
| `lib`   | Alias for `pizza`                            |
| `cache` | Replikeret nøgle/værdi-hjælpere (som før)    |

## NUI assets (udseende)

Paneler, tast-bokse, ringe og verdens-pin ligger som **SVG** i `web/build/assets/`. Du kan erstatte filerne med egne designs (behold filnavnene, eller opdatér `url('assets/...')` og `<img src="...">` i `web/build/index.html`). `fxmanifest.lua` inkluderer `web/build/assets/**/*`, så nye filer i mappen sendes med ressourcen.

## Credits

Inspireret af [st_libs](https://github.com/Stausi/st_libs) (modul-opdeling, init-mønster, resource-scoped notify).
