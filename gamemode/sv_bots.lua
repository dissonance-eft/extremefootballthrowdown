-- gamemode/sv_bots.lua
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
    local name = "Bot " .. math.random(1000)
    -- Try to find a unique name
    local distinct = false
    for i=1, 10 do
        local testName = table.Random({"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "EFTBot"}) .. " " .. math.random(99)
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
    
    local bot = player.CreateNextBot(name)
    if IsValid(bot) then
        bot.BotAI = Bot(bot)
        bot:SetTeam(teamid)
        -- Model set by player class usually, but ensure init
        bot:Spawn()
    end
    return bot
end

local function RemoveBot(bot)
    if IsValid(bot) and bot:IsBot() then
        bot:Kick("Removed")
    end
end

local function BalanceTeams()
    if not GetConVar("eft_bots_enabled"):GetBool() then return end
    
    if not ConVarExists("eft_bots_count") then
        CreateConVar("eft_bots_count", "6", FCVAR_NOTIFY, "Target number of players per team (Bots fill gaps)")
    end

    local targetPerTeam = 3 -- Hardcoded requirement: 3 per team
    
    local redTotal = team.NumPlayers(TEAM_RED)
    local blueTotal = team.NumPlayers(TEAM_BLUE)
    
    -- Add bots if needed
    if redTotal < targetPerTeam then
        CreateBot(TEAM_RED)
    elseif blueTotal < targetPerTeam then
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

concommand.Add("eft_bot_add", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local teamid = tonumber(args[1]) or TEAM_RED
    CreateBot(teamid)
    print("[EFT Bots] Added bot to " .. team.GetName(teamid))
end)

concommand.Add("eft_bot_remove", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    for _, bot in ipairs(player.GetBots()) do
        RemoveBot(bot)
        print("[EFT Bots] Removed " .. bot:Nick())
        return
    end
    print("[EFT Bots] No bots to remove")
end)

concommand.Add("eft_bot_kick_all", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    for _, bot in ipairs(player.GetBots()) do
        RemoveBot(bot)
    end
    print("[EFT Bots] Removed all bots")
end)

print("[EFT] Bot Entry Point Loaded")
