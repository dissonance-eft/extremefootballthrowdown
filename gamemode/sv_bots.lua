-- gamemode/sv_bots.lua
/// MANIFEST LINKS:
/// Mechanics: B-000 (Bots), M-110 (Charge logic)
/// Principles: P-060 (Bot Imperfection), C-005 (Predictive Positioning)
/// Scenarios: S-020 (Bot Positioning), A-001 to A-008 (Archetypes)
-- Bridge between GMod engine hooks and the OOP Bot class (obj_bot.lua)

if not ConVarExists("eft_bots_enabled") then
    CreateConVar("eft_bots_enabled", "1", FCVAR_NOTIFY, "Enable EFT bots")
end
CreateConVar("eft_bots_skill", "1.0", FCVAR_NOTIFY, "Bot skill multiplier (0.1 - 2.0)")

-- ============================================================================
-- BOT MANAGEMENT
-- ============================================================================

local function CreateBot(teamid)
    if not teamid then return end
    if game.SinglePlayer() then return end -- Can't create bots in singleplayer
    
    -- Human-like Bot Names (No more "Bot 34")
    local botNames = {
        "ViperBot", "CobraBot", "PythonBot", "RaptorBot", "RexBot", "TankBot", "DozerBot",
        "LocoBot", "PsychoBot", "GonzoBot", "ZeroBot", "GlitchBot", "SystemBot", "ErrorBot",
        "NeonBot", "FluxBot", "BitBot", "ByteBot", "PixelBot", "VoxelBot",
        "AlphaBot", "BravoBot", "CharlieBot", "DeltaBot", "EchoBot", "FoxtrotBot",
        "VectorBot", "VertexBot", "PolygonBot", "ShaderBot"
    }
    
    local name = "Bot"
    local distinct = false
    
    -- Try 10 times to pick a unique unused name
    for i=1, 10 do
        local testName = table.Random(botNames)
        local taken = false
        for _, v in ipairs(player.GetAll()) do
            if v:Nick() == testName then taken = true break end
        end
        
        if not taken then
            name = testName
            distinct = true
            break
        end
    end
    
    -- Fallback if server is full of named bots
    if not distinct then
        name = "Bot " .. math.random(100, 999)
    end
    
    local bot = player.CreateNextBot(name)
    if not IsValid(bot) then return end -- CreateFakeClient failed (server full or singleplayer)
    
    bot.BotAI = Bot(bot)
    bot:SetTeam(teamid)
    bot:Spawn()
    return bot
end

local function RemoveBot(bot)
    if IsValid(bot) and bot:IsBot() then
        bot:Kick("Removed")
    end
end

local function BalanceTeams()
    if not GetConVar("eft_bots_enabled"):GetBool() then return end
    
    -- Default to 10 bots total (5 per team) if convar missing
    local totalBots = 10
    if ConVarExists("eft_bots_count") then
        totalBots = GetConVar("eft_bots_count"):GetInt()
    else
        CreateConVar("eft_bots_count", "10", FCVAR_NOTIFY, "Target number of players per team (Bots fill gaps)")
    end

    local targetPerTeam = math.ceil(totalBots / 2)
    
    local redTotal = team.NumPlayers(TEAM_RED)
    local blueTotal = team.NumPlayers(TEAM_BLUE)
    
    -- Add bots if needed
    -- Use independent IFs so both teams can fill simultaneously
    if redTotal < targetPerTeam then
        CreateBot(TEAM_RED)
    end
    
    if blueTotal < targetPerTeam then
        CreateBot(TEAM_BLUE)
    end
    
    -- Remove bots if too many (and humans are present)
    if redTotal > targetPerTeam then
        for _, ply in ipairs(team.GetPlayers(TEAM_RED)) do
            if ply:IsBot() then 
                ply:Kick("Balancing")
                break 
            end
        end
    end
    
    if blueTotal > targetPerTeam then
        for _, ply in ipairs(team.GetPlayers(TEAM_BLUE)) do
            if ply:IsBot() then 
                ply:Kick("Balancing")
                break 
            end
        end
    end
end

timer.Create("EFTBotBalance", 2.0, 0, BalanceTeams)
hook.Add("InitPostEntity", "EFTBotInitSpawn", function()
    -- Spawn immediately on map load
    timer.Simple(1, function() 
        for i=1, 6 do BalanceTeams() end 
    end) 
end)

-- ============================================================================
-- HOOKS
-- ============================================================================

hook.Add("StartCommand", "EFTBotControl", function(bot, cmd)
    if bot.BotAI then
        bot.BotAI:BuildCommand(cmd)
    end
end)

hook.Add("SetupMove", "EFTBotMove", function(bot, mv, cmd)
    if bot.BotAI and bot:Alive() then
         -- Ensure move angles match eye angles for turn penalty logic
         mv:SetMoveAngles(bot:EyeAngles())
    end
end)

hook.Add("Think", "EFTBotThink", function()
    if not GetConVar("eft_bots_enabled"):GetBool() then return end
    
    for _, bot in ipairs(player.GetBots()) do
        if not bot.BotAI then
            bot.BotAI = Bot(bot) -- Lazy Init
        end
        
        if IsValid(bot) and bot:Alive() then
             bot.BotAI:Think()
             
             -- Physics Safety Clamp (Anti-Spam)
             -- "Crazy angular velocity on entity" fix
             local phys = bot:GetPhysicsObject()
             if IsValid(phys) then
                 local angVel = phys:GetAngleVelocity()
                 if angVel:LengthSqr() > 1000000 then -- > 1000 magnitude
                     phys:SetAngleVelocity(Vector(0,0,0))
                     phys:Sleep() -- Briefly sleep to kill momentum
                     phys:Wake()
                 end
             end
        elseif IsValid(bot) and not bot:Alive() then
             -- Auto-respawn logic
             if not bot.BotAI.deathTime then
                 bot.BotAI.deathTime = CurTime()
             end
             if CurTime() - (bot.BotAI.deathTime or 0) >= 4 then
                 bot.BotAI.deathTime = nil
                 bot:Spawn()
             end
        end
    end
end)

hook.Add("PlayerDisconnected", "EFTBotCleanup", function(ply)
    -- cleanup handled by GC mostly, but good to be explicit
    ply.BotAI = nil
end)

-- Celebration Logic
local function TriggerBotVictory(winner)
    if not winner then return end
    for _, bot in ipairs(team.GetPlayers(winner)) do
        if IsValid(bot) and bot.BotAI and bot:Alive() then
             bot.BotAI.state = 6 -- CELEBRATE
             bot.BotAI.celebrateStart = CurTime()
             bot.BotAI.didAct = false
             bot.BotAI.throwState = nil
             bot.BotAI.wantReload = false
        end
    end
end

hook.Add("OnRoundEnd", "EFTBotCelebration", TriggerBotVictory)
hook.Add("OnRoundResult", "EFTBotCelebrationResult", function(winner) TriggerBotVictory(winner) end)


-- ============================================================================
-- CONSOLE COMMANDS
-- ============================================================================

concommand.Add("eft_bots", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args[1])
    if val == nil then
        print("[EFT Bots] Usage: eft_bots 0 (disable) | eft_bots 1 (enable, fill to 5v5)")
        return
    end
    
    if val == 0 then
        GetConVar("eft_bots_enabled"):SetBool(false)
        for _, bot in ipairs(player.GetBots()) do
            bot:Kick("Bots disabled")
        end
        print("[EFT Bots] Disabled — all bots removed")
    else
        GetConVar("eft_bots_enabled"):SetBool(true)
        print("[EFT Bots] Enabled — filling to 5v5")
        timer.Simple(0.5, function() for i = 1, 10 do BalanceTeams() end end)
    end
end, nil, "Toggle bots: 0 = off, 1 = on (5v5)")

print("[EFT] Bot Entry Point Loaded")
