-- D3bot Navigation Engine — EFT Integration
-- Source: https://github.com/Dadido3/D3bot (MIT License)
-- Stripped of Zombie Survival-specific content; navigation engine only.
--
-- What's kept:   node graph, A* pathfinder, in-game editor, debug viz, utilities
-- What's removed: ZS bot handler, survivor/zombie spawn logic, barricade detection,
--                 extra prop system, ZS config, ULX integration, bot name lists
--
-- Node graphs are saved to data/d3bot/navmesh/map/<mapname>.txt
-- Use the in-game editor (!bot editmesh) to place nodes on EFT maps.

-- Load core engine via azlib module system.
-- azlib calls include(path)(lib) for each entry; each file returns function(lib).
include("lib/d3bot/azlib.lua")("D3bot", {
    "lib/d3bot/1_navmesh.lua",
    "lib/d3bot/1_navmesh_cl.lua",
    "lib/d3bot/1_navmesh_sv.lua",
    "lib/d3bot/2_mapnavmeshui_cl.lua",
    "lib/d3bot/2_mapnavmeshui_sv.lua",
})

D3bot.BotHooksId = "EFT_D3bot"

-- Shared files (run on both server and client)
AddCSLuaFile("lib/d3bot/sh_async.lua")
AddCSLuaFile("lib/d3bot/sh_utilities.lua")
include("lib/d3bot/sh_async.lua")
include("lib/d3bot/sh_utilities.lua")

-- Client files
AddCSLuaFile("lib/d3bot/cl_convars.lua")
AddCSLuaFile("lib/d3bot/cl_ui.lua")
AddCSLuaFile("lib/d3bot/vgui/meshing_main.lua")
if CLIENT then
    include("lib/d3bot/cl_convars.lua")
    include("lib/d3bot/cl_ui.lua")
    include("lib/d3bot/vgui/meshing_main.lua")
end

-- Server files
if SERVER then
    include("lib/d3bot/sv_eft_config.lua")   -- EFT nav config (not ZS config)
    include("lib/d3bot/sv_utilities.lua")
    include("lib/d3bot/sv_path.lua")
    include("lib/d3bot/sv_extend_player.lua") -- Bot attack prediction helpers
    include("lib/d3bot/sv_debug.lua")
    include("lib/d3bot/sv_navmeta.lua")
    include("lib/d3bot/sv_navmesh_generate.lua")
    -- sv_benchmark.lua omitted (dev tool, load manually if needed)
    -- sv_zs_bot_handler/ omitted (ZS-specific; would not load in EFT regardless)
    -- sv_names.lua omitted (EFT uses sv_bots.lua for bot names)
end
