-- gamemode/cl_manifest_debug.lua
-- Developer debug HUD for troubleshooting EFT.
-- Enabled via: eft_dev 1
-- Shows: game state, ball state, carrier info, local player state,
--        entity manifest links (aim at entity), and bot overlays (server-side).

include("cl_manifest_data.lua")

-- Colors
local C_BG = Color(20, 20, 20, 220)
local C_BG_LIGHT = Color(30, 30, 30, 200)
local C_TEXT = Color(220, 220, 220, 255)
local C_ACCENT = Color(255, 180, 50, 255)
local C_SUBTLE = Color(150, 150, 150, 255)
local C_RED = Color(255, 100, 100, 255)
local C_GREEN = Color(100, 255, 100, 255)
local C_BLUE = Color(100, 150, 255, 255)
local C_YELLOW = Color(255, 255, 100, 255)
local C_CYAN = Color(100, 255, 255, 255)

-- Fonts
surface.CreateFont("EFT_DevFont", {
    font = "Consolas",
    size = 14,
    weight = 500,
    antialias = true,
})

surface.CreateFont("EFT_DevFontSmall", {
    font = "Consolas",
    size = 12,
    weight = 400,
    antialias = true,
})

surface.CreateFont("EFT_DevFontBold", {
    font = "Consolas",
    size = 14,
    weight = 700,
    antialias = true,
})

-- Helper: get a state name from its index
local function GetStateName(stateIdx)
    if not stateIdx then return "nil" end
    local stateTab = STATES and STATES[stateIdx]
    if stateTab and stateTab.FileName then
        return string.upper(stateTab.FileName) .. " (" .. stateIdx .. ")"
    end
    return tostring(stateIdx)
end

-- Helper: draw a labeled panel section
local function DrawSection(x, y, w, title, lines)
    local lineH = 16
    local h = 20 + #lines * lineH + 4
    draw.RoundedBox(4, x, y, w, h, C_BG)
    draw.SimpleText(title, "EFT_DevFontBold", x + 6, y + 2, C_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    for i, line in ipairs(lines) do
        local lineY = y + 20 + (i - 1) * lineH
        if istable(line) then
            -- {label, value, color}
            draw.SimpleText(line[1], "EFT_DevFont", x + 8, lineY, C_SUBTLE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(line[2]), "EFT_DevFont", x + 130, lineY, line[3] or C_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
            draw.SimpleText(tostring(line), "EFT_DevFont", x + 8, lineY, C_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    return h
end

-- Helper: draw manifest code box for an entity
local function DrawManifestBox(x, y, ent, mapping)
    local ids = mapping
    if not ids or #ids == 0 then return 0 end

    local w = 300
    local h = 24 + (#ids * 16) + 8

    draw.RoundedBox(4, x, y, w, h, C_BG)
    draw.SimpleText("MANIFEST CODES", "EFT_DevFontBold", x + 8, y + 4, C_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(ent:GetClass(), "EFT_DevFontSmall", x + w - 8, y + 4, C_SUBTLE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    for i, id in ipairs(ids) do
        local def = ManifestData and ManifestData.Definitions and ManifestData.Definitions[id] or "???"
        local lineY = y + 24 + (i - 1) * 16

        local col = C_TEXT
        if id:StartWith("M-") then col = C_RED
        elseif id:StartWith("P-") then col = C_GREEN
        elseif id:StartWith("C-") then col = C_BLUE
        elseif id:StartWith("S-") then col = C_YELLOW
        elseif id:StartWith("E-") then col = C_CYAN
        end

        draw.SimpleText(id, "EFT_DevFont", x + 8, lineY, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(def, "EFT_DevFont", x + 54, lineY, C_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    return h
end

hook.Add("HUDPaint", "EFT_DevHUD", function()
    if GetConVarNumber("eft_dev") == 0 then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local x = 8
    local y = 8
    local w = 320

    -- ================================================================
    -- 1. GAME STATE
    -- ================================================================
    local gameLines = {}
    local inRound = GetGlobalBool("InRound", false)
    local overtime = GetGlobalBool("overtime", false)
    local warmup = GAMEMODE:IsWarmUp()
    local timeLeft = GAMEMODE:GetGameTimeLeft()
    local bonusTime = GetGlobalFloat("BonusTime", 0)
    local redScore = team.GetScore(TEAM_RED)
    local blueScore = team.GetScore(TEAM_BLUE)

    local phaseStr = "UNKNOWN"
    if warmup then phaseStr = "WARMUP"
    elseif not inRound then phaseStr = "BETWEEN ROUNDS"
    elseif overtime then phaseStr = "OVERTIME"
    else phaseStr = "IN ROUND"
    end

    table.insert(gameLines, {"Phase", phaseStr, warmup and C_YELLOW or (overtime and C_RED or C_GREEN)})
    table.insert(gameLines, {"Score", redScore .. " RED  -  BLUE " .. blueScore})
    table.insert(gameLines, {"Score Limit", tostring(GAMEMODE.ScoreLimit or "?")})
    if timeLeft >= 0 then
        table.insert(gameLines, {"Time Left", util.ToMinutesSeconds(timeLeft)})
    else
        table.insert(gameLines, {"Time Left", "unlimited", C_SUBTLE})
    end
    if bonusTime > 0 then
        table.insert(gameLines, {"Bonus Time", string.format("%.1fs", bonusTime), C_YELLOW})
    end
    table.insert(gameLines, {"Players", #team.GetPlayers(TEAM_RED) .. "R / " .. #team.GetPlayers(TEAM_BLUE) .. "B"})

    local pityRed = team.HasPity and team.HasPity(TEAM_RED) or false
    local pityBlue = team.HasPity and team.HasPity(TEAM_BLUE) or false
    if pityRed or pityBlue then
        local pityTeam = pityRed and "RED" or "BLUE"
        table.insert(gameLines, {"Pity Active", pityTeam, C_YELLOW})
    end

    local h = DrawSection(x, y, w, "GAME STATE", gameLines)
    y = y + h + 4

    -- ================================================================
    -- 2. BALL STATE
    -- ================================================================
    local ball = GAMEMODE:GetBall()
    local ballLines = {}

    if IsValid(ball) then
        local carrier = ball:GetCarrier()
        local ballPos = ball:GetPos()
        local ballHome = GAMEMODE:GetBallHome()

        table.insert(ballLines, {"Position", string.format("%.0f %.0f %.0f", ballPos.x, ballPos.y, ballPos.z)})

        if IsValid(carrier) then
            local teamCol = carrier:Team() == TEAM_RED and C_RED or C_BLUE
            table.insert(ballLines, {"Carrier", carrier:Nick(), teamCol})
            table.insert(ballLines, {"Carrier Team", carrier:Team() == TEAM_RED and "RED" or "BLUE", teamCol})
            table.insert(ballLines, {"Carrier Speed", string.format("%.0f HU/s", carrier:GetVelocity():Length2D())})
            table.insert(ballLines, {"Carrier State", GetStateName(carrier:GetState())})

            -- Distance to goals
            local enemyTeam = GAMEMODE:GetOppositeTeam(carrier:Team())
            local goalPos = GAMEMODE:GetGoalCenter(enemyTeam)
            if goalPos ~= vector_origin then
                local dist = carrier:GetPos():Distance(goalPos)
                local urgCol = dist < 500 and C_RED or (dist < 1000 and C_YELLOW or C_TEXT)
                table.insert(ballLines, {"Dist to Goal", string.format("%.0f HU", dist), urgCol})
            end
        else
            table.insert(ballLines, {"Carrier", "NONE (loose)", C_YELLOW})
            local phys = ball:GetPhysicsObject()
            if IsValid(phys) then
                local vel = phys:GetVelocity()
                table.insert(ballLines, {"Ball Vel", string.format("%.0f HU/s", vel:Length())})
            end
        end

        if ballHome ~= vector_origin then
            table.insert(ballLines, {"Home (spawn)", string.format("%.0f %.0f %.0f", ballHome.x, ballHome.y, ballHome.z)})
        end

        -- Ball state (DT var if available)
        if ball.GetState then
            local ballState = ball:GetState()
            if ballState and ballState ~= 0 then
                local bStateTab = ball.GetStateTable and ball:GetStateTable() or nil
                local bStateName = (bStateTab and bStateTab.FileName) and bStateTab.FileName or tostring(ballState)
                table.insert(ballLines, {"Ball State", string.upper(bStateName), C_CYAN})
            end
        end
    else
        table.insert(ballLines, {"Status", "NO BALL ENTITY", C_RED})
    end

    h = DrawSection(x, y, w, "BALL STATE", ballLines)
    y = y + h + 4

    -- ================================================================
    -- 3. LOCAL PLAYER STATE
    -- ================================================================
    if ply:Alive() then
        local plLines = {}
        local speed = ply:GetVelocity():Length2D()
        local charging = speed >= 300 and ply:OnGround()

        table.insert(plLines, {"Speed", string.format("%.0f HU/s", speed), charging and C_GREEN or (speed < 100 and C_RED or C_TEXT)})
        table.insert(plLines, {"Charge State", charging and "YES" or "NO", charging and C_GREEN or C_RED})
        table.insert(plLines, {"State", GetStateName(ply:GetState())})
        table.insert(plLines, {"Team", ply:Team() == TEAM_RED and "RED" or (ply:Team() == TEAM_BLUE and "BLUE" or "SPEC")})
        table.insert(plLines, {"Health", ply:Health() .. " / " .. ply:GetMaxHealth()})
        table.insert(plLines, {"On Ground", ply:OnGround() and "yes" or "NO", ply:OnGround() and C_SUBTLE or C_YELLOW})

        local carry = ply:GetCarry()
        if IsValid(carry) then
            table.insert(plLines, {"Carrying", carry:GetClass(), C_CYAN})
        end

        h = DrawSection(x, y, w, "LOCAL PLAYER", plLines)
        y = y + h + 4
    end

    -- ================================================================
    -- 4. MANIFEST ENTITY LOOKUP (aim at entity)
    -- ================================================================
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 500,
        filter = ply
    })

    if tr.Entity and tr.Entity:IsValid() then
        local ent = tr.Entity
        local class = ent:GetClass()

        -- Entity info box
        local entLines = {}
        table.insert(entLines, {"Class", class})
        table.insert(entLines, {"Index", tostring(ent:EntIndex())})
        table.insert(entLines, {"Position", string.format("%.0f %.0f %.0f", ent:GetPos().x, ent:GetPos().y, ent:GetPos().z)})

        if ent:IsPlayer() then
            table.insert(entLines, {"Name", ent:Nick()})
            table.insert(entLines, {"State", GetStateName(ent:GetState())})
            table.insert(entLines, {"Speed", string.format("%.0f", ent:GetVelocity():Length2D())})
            table.insert(entLines, {"Team", ent:Team() == TEAM_RED and "RED" or "BLUE"})
            if ent.Personality then
                table.insert(entLines, {"Personality", ent.Personality, C_CYAN})
            end
        end

        -- Draw entity info on right side
        local rx = ScrW() - w - 8
        h = DrawSection(rx, 8, w, "AIMED ENTITY", entLines)

        -- Manifest codes
        local mapping = ManifestData.Mappings[class]
        if not mapping and ent:IsPlayer() then
            mapping = ManifestData.Mappings["player"]
        end

        if mapping then
            DrawManifestBox(rx, 8 + h + 4, ent, mapping)
        end
    end
end)
