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
--
-- NOTE: include() and AddCSLuaFile() are relative to THIS file's directory
-- (gamemode/lib/d3bot/), so all paths use bare filenames, not "lib/d3bot/X".

-- Load core engine via azlib module system.
-- azlib calls include(path)(lib) for each entry; each file returns function(lib).
include("azlib.lua")("D3bot", {
    "1_navmesh.lua",
    "1_navmesh_cl.lua",
    "1_navmesh_sv.lua",
    "2_mapnavmeshui_cl.lua",
    "2_mapnavmeshui_sv.lua",
})

D3bot.BotHooksId = "EFT_D3bot"

-- Shared files (run on both server and client)
AddCSLuaFile("sh_async.lua")
AddCSLuaFile("sh_utilities.lua")
include("sh_async.lua")
include("sh_utilities.lua")

-- Client files
AddCSLuaFile("cl_convars.lua")
AddCSLuaFile("cl_ui.lua")
AddCSLuaFile("vgui/meshing_main.lua")
if CLIENT then
    include("cl_convars.lua")
    include("cl_ui.lua")
    include("vgui/meshing_main.lua")
end

-- Server files
if SERVER then
    include("sv_eft_config.lua")   -- EFT nav config (not ZS config)
    include("sv_utilities.lua")
    include("sv_path.lua")
    include("sv_extend_player.lua") -- Bot attack prediction helpers
    include("sv_debug.lua")
    include("sv_navmeta.lua")
    include("sv_navmesh_generate.lua")
    -- sv_benchmark.lua omitted (dev tool, load manually if needed)
    -- sv_zs_bot_handler/ omitted (ZS-specific; would not load in EFT regardless)
    -- sv_names.lua omitted (EFT uses sv_bots.lua for bot names)
end
