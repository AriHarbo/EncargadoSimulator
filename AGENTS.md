# Encargado Simulator — Godot project

Identifiers and comments in this repo are written in Spanish (with some English mixed in). Keep that convention.

## Commands / tooling
- No build tooling, no tests, no CI, no linter. Verification = open the project in the Godot editor and run (F5).
- Godot 4.4, renderer "Forward Plus". Nothing to install or compile; the `.godot/` import cache is gitignored.
- Main scene: `src/scenes/fields/mapa.tscn`. The `build/` directory exists but is empty (used/not needed).

## Layout
- `src/scenes/**` — scenes; `src/scripts/**` — GDScript, mirrored by category (player, npcs, tools, props, enviroment, cleanables, ui, autoload, resources, 3d_areas, generics, fields).
- `src/resources/**` — `.tres` data assets: `tareas/`, `llamadas/` (boss calls), `shop_items/`.
- `.tres` resources use `class_name` types defined in `src/scripts/resources/` (`Task`, `BossCall`, `ShopItem`).
- Folder typo: the "environment" folder is spelled `enviroment` — match it.

## Autoloads (project.godot)
- `GameManager` — day loop: time, task pool/state, money, boss-call triggers, end-of-day summary. Source of truth for all task flow.
- `OrderManager` — simple "one order at a time" flag/box state.
- `DialogoUi` — dialog UI scene autoload.

## Quirks & gotchas
- Physics: `common/physics_ticks_per_second=180` (non-default).
- Game clock: `segundos_por_hora = 60` (one game hour ≈ 60 real sec); day runs `8.0 → 30.0` (6:00 AM next day). Phases: `manana` (<13), `tarde` (<20), `noche`.
- New day content is NOT auto-discovered: every task `.tres` and boss call `.tres` must be registered by path in `GameManager._cargar_recursos()` (`src/scripts/autoload/game_manager.gd`). Adding a file alone does nothing.
- `project.godot` has a stray duplicate `drop` input action inside the `[layer_names]` section (corrupted edit) — be careful when editing it, and don't copy that section as a template.
- Interactable physics: `3d_physics/layer_2` is named "Interactable" and is the layer interactables live on.
- Godot 4.4 uses UIDs; `.uid` files next to `.gd` scripts and `uid://...` refs in project/scene files are normal.

## Task id naming trap
Task .tres filenames do NOT match their resource `id` (e.g. file `tarea_01_presentaciones.tres`, `id = "presentaciones"`).
- Completion/assignment use the resource `id`: `GameManager.completar_tarea("limpiar_hab1")`, `asignar_tareas(ids)`, and `BossCall.tareas_a_agregar` / `.tarea_activadora`.
- BUT `GameManager.requisitos_npc_tarea` (multi-NPC dialog tasks) and the NPC scenes' `tarea_a_completar` currently use the filename-style key (`"tarea_01_presentaciones"`), which does not match the resource id `"presentaciones"`. Before wiring a new NPC-based task, verify which scheme each side uses.
- Multi-NPC flow: NPCs call `GameManager.registrar_dialogo_npc(tarea_id, npc_id)`; tasks requiring several NPCs must be listed in `requisitos_npc_tarea` with the required `npc_id`s or they complete on the first NPC.

## Input actions
WASD + Space (jump), E (interact / rotate right), Q (drop / rotate left), 1–4 (hotbar slots via `ui_slot_N`), Ctrl/Shift (crouch). Defined in `[input]` in `project.godot`.