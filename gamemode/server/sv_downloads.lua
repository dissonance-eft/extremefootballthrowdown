if not SERVER then return end
-- Tells clients to download maps via FastDL (sv_downloadurl in server.cfg).
-- Maps are served as .bsp.bz2 from http://165.22.35.48/garrysmod/maps/
-- Do NOT add non-map content here -- materials/sounds are in the Workshop addon.

local maps = {
    "maps/eft_baseballdash_v3.bsp",
    "maps/eft_big_metal03r1.bsp",
    "maps/eft_bloodbowl_v5.bsp",
    "maps/eft_castle_warfare.bsp",
    "maps/eft_chamber_v3.bsp",
    "maps/eft_cosmic_arena_v2.bsp",
    "maps/eft_countdown_v4.bsp",
    "maps/eft_handegg_r2.bsp",
    "maps/eft_lake_parima_v2.bsp",
    "maps/eft_legoland_v2.bsp",
    "maps/eft_minecraft_v4.bsp",
    "maps/eft_miniputt_v1r.bsp",
    "maps/eft_sky_metal_v2.bsp",
    "maps/eft_skyline_v2.bsp",
    "maps/eft_skystep_v4.bsp",
    "maps/eft_slamdunk_v6.bsp",
    "maps/eft_soccer_b4.bsp",
    "maps/eft_spacejump_v6.bsp",
    "maps/eft_temple_sacrifice_v3.bsp",
    "maps/eft_tunnel_v2.bsp",
    "maps/eft_turbines_v2.bsp",
}

for _, path in ipairs(maps) do
    resource.AddFile(path)
end
