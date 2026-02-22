-- D3bot configuration for Extreme Football Throwdown
-- Navigation-relevant settings only. All ZS-specific values removed.

-- Trace shape for bot line-of-sight checks
D3bot.BotSeeTr = {
    mins = Vector(-15, -15, -15),
    maxs = Vector(15, 15, 15),
    mask = MASK_PLAYERSOLID
}

-- Entities that block node placement (in-editor feedback)
D3bot.NodeBlocking = {
    mins = Vector(-1, -1, -1),
    maxs = Vector(1, 1, 1),
    classes = {
        func_breakable = true, prop_physics = true, prop_dynamic = true,
        prop_door_rotating = true, func_door = true, func_physbox = true,
        func_physbox_multiplayer = true, func_movelinear = true
    }
}

-- Entities that block nodes on the map (saved/loaded check)
D3bot.NodeBlockingMap = {
    mins = Vector(-1, -1, -1),
    maxs = Vector(1, 1, 1),
    classes = {
        func_breakable = true, prop_dynamic = true,
        prop_door_rotating = true, func_door = true, func_movelinear = true
    }
}

-- EFT maps do not have generated nav meshes (open-air BSP, no info_player_start seeds).
-- Always use hand-placed D3bot node graphs; never fall back to Valve nav mesh.
D3bot.ValveNav = false
D3bot.ValveNavOverride = false

-- Path cost for links where a bot has died recently (discourages repeated death paths)
D3bot.LinkDeathCostRaise = 300

-- Rotation: how fast bots turn toward their target (lower = smoother, higher = snappier)
D3bot.BotAngLerpFactor = 0.125
D3bot.BotAttackAngLerpFactor = 0.125
D3bot.FaceTargetOffshootFactor = 0.2

-- Probability of NOT jumping/ducking per think (antichance = 1/N chance of action)
D3bot.BotJumpAntichance = 25
D3bot.BotDuckAntichance = 25

-- Node damage: not applicable in EFT (no damage zones)
D3bot.DisableNodeDamage = true
D3bot.NodeDamageInterval = 1

-- Bot join/leave sync delay (seconds)
D3bot.BotUpdateDelay = 1
