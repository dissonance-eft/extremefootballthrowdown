-- gamemode/cl_mapvote.lua
/// MANIFEST LINKS:
/// Principles: C-007 (Migrating Conflict Zone - Map Choice)
-- Map Vote UI for EFT (client side)
-- Modern vote screen with map thumbnail images, vote counts, and player avatars.
--
-- s&box mapping:
--   This entire file → Razor Component <MapVotePanel> with @inject IMapVoteService
--   DPanel / derma  → <div>, <button>, <img> in Razor markup
--   net.Receive      → [Rpc.Broadcast] void OnMapVoteStarted(...)
--   surface.*        → Sandbox.UI.Panel.Draw() overrides
--
-- IMAGE SUPPORT (checked in order):
--   1. materials/mapvote/<mapname>.vtf/.vmt   (user-provided VTF, best quality)
--   2. materials/mapvote/<mapname>.png         (user-provided PNG, auto-loaded)
--   3. Gamemode backgrounds/ folder            (existing main menu JPGs, via DImage)
--      Maps are fuzzy-matched: "eft_bloodbowl_v5" → "bloodbowl.jpg"
--   4. maps/thumb/<mapname>.png                (GMod auto-generated)
--   5. maps/<mapname>.png                      (fallback)
--   6. Placeholder with map name text

-- ============================================================================
-- FONTS
-- ============================================================================

surface.CreateFont("EFT_MapVoteTitle", {
    font = "Trebuchet MS",
    size = 32,
    weight = 700,
    antialias = true,
    shadow = true,
})

surface.CreateFont("EFT_MapVoteName", {
    font = "Trebuchet MS",
    size = 16,
    weight = 700,
    antialias = true,
    shadow = true,
})

surface.CreateFont("EFT_MapVoteCountdown", {
    font = "Tahoma",
    size = 36,
    weight = 700,
    antialias = true,
    shadow = true,
})

surface.CreateFont("EFT_MapVoteCount", {
    font = "Tahoma",
    size = 20,
    weight = 700,
    antialias = true,
    shadow = true,
})

-- ============================================================================
-- SHARED STATE
-- ============================================================================

MapVote = MapVote or {}
MapVote.CurrentMaps = {}
MapVote.Votes = {}       -- SteamID -> map index
MapVote.EndTime = 0
MapVote.Panel = nil
MapVote.Allow = false

MapVote.UPDATE_VOTE = 1
MapVote.UPDATE_WIN  = 3

-- ============================================================================
-- MAP THUMBNAIL SYSTEM
-- ============================================================================

--- Background image name → map name keyword mapping.
--- The backgrounds/ folder has images like "bloodbowl.jpg" that correspond to
--- maps like "eft_bloodbowl_v5". We strip the eft_/xft_ prefix and version
--- suffix to fuzzy-match.
local backgroundFiles = {} -- Populated on load
local mapMaterialCache = {} -- mapName -> Material or false

--- Scan the backgrounds folder for available images.
local function ScanBackgrounds()
    local gmFolder = GAMEMODE and GAMEMODE.Folder or "gamemodes/extremefootballthrowdown"
    -- backgrounds/ is relative to the gamemode root
    local files = file.Find(gmFolder .. "/backgrounds/*.jpg", "GAME")
    for _, f in ipairs(files or {}) do
        local name = f:sub(1, -5):lower() -- strip .jpg
        backgroundFiles[name] = gmFolder .. "/backgrounds/" .. f
    end
    -- Also check .png
    local pngFiles = file.Find(gmFolder .. "/backgrounds/*.png", "GAME")
    for _, f in ipairs(pngFiles or {}) do
        local name = f:sub(1, -5):lower() -- strip .png
        backgroundFiles[name] = gmFolder .. "/backgrounds/" .. f
    end
end

--- Extract a fuzzy keyword from a map name for background matching.
--- "eft_bloodbowl_v5" → "bloodbowl"
--- "xft_cosmic_arena_v2" → "cosmicarena" (spaces/underscores stripped)
---@param mapName string
---@return string keyword
local function MapNameToKeyword(mapName)
    local name = mapName:lower()
    -- Strip prefix
    name = name:gsub("^eft_", ""):gsub("^xft_", "")
    -- Strip version suffix like _v2, _v5, _b4, _r2, 03r1
    name = name:gsub("_%w?%d+$", ""):gsub("%d+r%d+$", "")
    -- Strip remaining trailing underscores
    name = name:gsub("_+$", "")
    -- Remove underscores and spaces for fuzzy compare
    name = name:gsub("[_%s]", "")
    return name
end

--- Try to find a background image path that matches a map name.
---@param mapName string
---@return string? path The GAME-relative path to the image, or nil
local function FindBackgroundForMap(mapName)
    local keyword = MapNameToKeyword(mapName)

    -- Direct match
    if backgroundFiles[keyword] then
        return backgroundFiles[keyword]
    end

    -- Fuzzy: check if any background name is contained in the keyword or vice versa
    for bgName, bgPath in pairs(backgroundFiles) do
        local bgClean = bgName:gsub("[_%s]", "")
        if bgClean == keyword or keyword:find(bgClean, 1, true) or bgClean:find(keyword, 1, true) then
            return bgPath
        end
    end

    return nil
end

--- Try to load a map thumbnail material from multiple search paths.
---@param mapName string The map name (without .bsp)
---@return IMaterial|boolean mat The material, or false if not found
local function GetMapThumbnail(mapName)
    if mapMaterialCache[mapName] ~= nil then
        return mapMaterialCache[mapName]
    end

    -- 1. Check materials/mapvote/<mapname> (VTF/VMT or PNG)
    local mat = Material("mapvote/" .. mapName, "smooth")
    if mat and not mat:IsError() then
        mapMaterialCache[mapName] = mat
        return mat
    end

    -- 2. Check maps/thumb/<mapname>
    mat = Material("maps/thumb/" .. mapName, "smooth")
    if mat and not mat:IsError() then
        mapMaterialCache[mapName] = mat
        return mat
    end

    -- 3. Check maps/<mapname>
    mat = Material("maps/" .. mapName, "smooth")
    if mat and not mat:IsError() then
        mapMaterialCache[mapName] = mat
        return mat
    end

    -- Not found as a Material; mark as false (DImage will be tried in the panel)
    mapMaterialCache[mapName] = false
    return false
end

-- Scan backgrounds on load
timer.Simple(0, function()
    ScanBackgrounds()
end)

-- ============================================================================
-- COLORS
-- ============================================================================

local COLOR_BG = Color(20, 20, 30, 230)
local COLOR_HEADER = Color(30, 30, 50, 255)
local COLOR_MAP_BG = Color(40, 40, 60, 200)
local COLOR_MAP_HOVER = Color(60, 60, 90, 220)
local COLOR_MAP_VOTED = Color(80, 140, 220, 220)
local COLOR_MAP_WINNER = Color(50, 255, 100, 255)
local COLOR_VOTES = Color(255, 220, 50, 255)
local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_NO_THUMB = Color(60, 60, 80, 255)
local COLOR_COUNTDOWN = Color(255, 100, 100, 255)

-- ============================================================================
-- NET RECEIVE HANDLERS
-- ============================================================================

net.Receive("EFT_MapVoteStart", function()
    MapVote.CurrentMaps = {}
    MapVote.Allow = true
    MapVote.Votes = {}

    local amt = net.ReadUInt(32)
    for i = 1, amt do
        MapVote.CurrentMaps[i] = net.ReadString()
    end

    MapVote.EndTime = CurTime() + net.ReadUInt(32)

    -- Re-scan backgrounds in case they were loaded late
    ScanBackgrounds()

    if IsValid(MapVote.Panel) then
        MapVote.Panel:Remove()
    end

    MapVote.Panel = vgui.Create("EFT_MapVoteScreen")
    MapVote.Panel:SetMaps(MapVote.CurrentMaps)
end)

net.Receive("EFT_MapVoteUpdate", function()
    local updateType = net.ReadUInt(3)

    if updateType == MapVote.UPDATE_VOTE then
        local ply = net.ReadEntity()
        if IsValid(ply) then
            local mapId = net.ReadUInt(32)
            MapVote.Votes[ply:SteamID()] = mapId

            if IsValid(MapVote.Panel) then
                MapVote.Panel:UpdateVotes()
            end
        end
    elseif updateType == MapVote.UPDATE_WIN then
        local winnerId = net.ReadUInt(32)
        if IsValid(MapVote.Panel) then
            MapVote.Panel:ShowWinner(winnerId)
        end
    end
end)

net.Receive("EFT_MapVoteCancel", function()
    if IsValid(MapVote.Panel) then
        MapVote.Panel:Remove()
    end
end)

net.Receive("EFT_RTVNotify", function()
    chat.AddText(
        Color(255, 180, 50), "[RTV] ",
        Color(255, 255, 255), "The vote has been rocked! Map vote starting soon..."
    )
end)

-- ============================================================================
-- VOTE SCREEN PANEL
-- ============================================================================

local PANEL = {}

local THUMB_W = 200
local THUMB_H = 120
local CARD_PAD = 6
local CARD_W = THUMB_W + CARD_PAD * 2
local CARD_H = THUMB_H + 32 + CARD_PAD * 2  -- thumbnail + text + padding
local GRID_PAD = 8

function PANEL:Init()
    self:ParentToHUD()
    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)

    self.mapButtons = {}
    self.winnerID = nil
    self.myVote = nil

    -- Close button
    self.closeBtn = vgui.Create("DButton", self)
    self.closeBtn:SetText("X")
    self.closeBtn:SetFont("EFT_MapVoteName")
    self.closeBtn:SetTextColor(COLOR_WHITE)
    self.closeBtn:SetSize(32, 32)
    self.closeBtn.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(200, 50, 50, 200) or Color(100, 100, 100, 100)
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    self.closeBtn.DoClick = function()
        self:SetVisible(false)
    end
end

function PANEL:PerformLayout()
    self:SetSize(ScrW(), ScrH())
    self.closeBtn:SetPos(ScrW() - 44, 12)
end

function PANEL:SetMaps(maps)
    -- Clear old buttons
    for _, btn in ipairs(self.mapButtons) do
        if IsValid(btn) then btn:Remove() end
    end
    self.mapButtons = {}
    self.winnerID = nil
    self.myVote = nil

    -- Calculate grid layout
    local screenW, screenH = ScrW(), ScrH()
    local headerH = 80
    local availW = screenW - 60
    local availH = screenH - headerH - 40

    local cols = math.floor(availW / (CARD_W + GRID_PAD))
    cols = math.max(1, math.min(cols, 8))
    local rows = math.ceil(#maps / cols)

    -- Scale down if too many rows to fit
    local totalGridH = rows * (CARD_H + GRID_PAD)
    local scale = 1
    if totalGridH > availH then
        scale = availH / totalGridH
    end

    local cardW = math.floor(CARD_W * scale)
    local cardH = math.floor(CARD_H * scale)
    local thumbW = math.floor(THUMB_W * scale)
    local thumbH = math.floor(THUMB_H * scale)
    local gridPad = math.floor(GRID_PAD * scale)
    local cardPad = math.floor(CARD_PAD * scale)

    -- Recalculate cols with scaled size
    cols = math.floor(availW / (cardW + gridPad))
    cols = math.max(1, math.min(cols, 8))
    rows = math.ceil(#maps / cols)

    local gridW = cols * (cardW + gridPad) - gridPad
    local gridH = rows * (cardH + gridPad) - gridPad
    local startX = math.floor((screenW - gridW) / 2)

    -- Create scroll panel if needed
    if not IsValid(self.scrollPanel) then
        self.scrollPanel = vgui.Create("DScrollPanel", self)
    end
    self.scrollPanel:SetPos(0, headerH)
    self.scrollPanel:SetSize(screenW, availH + 20)

    local canvas = self.scrollPanel:GetCanvas()

    for i, mapName in ipairs(maps) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = startX + col * (cardW + gridPad)
        local y = 20 + row * (cardH + gridPad)

        local btn = vgui.Create("DButton", canvas)
        btn:SetPos(x, y)
        btn:SetSize(cardW, cardH)
        btn:SetText("")
        btn.mapID = i
        btn.mapName = mapName
        btn.voteCount = 0
        btn.isWinner = false
        btn.flashCol = nil

        -- Try to get a Material-based thumbnail
        local thumbMat = GetMapThumbnail(mapName)
        btn.thumbMat = thumbMat

        -- If no Material found, try the backgrounds/ folder via DImage
        btn.thumbImage = nil
        if not thumbMat then
            local bgPath = FindBackgroundForMap(mapName)
            if bgPath then
                local img = vgui.Create("DImage", btn)
                img:SetPos(cardPad, cardPad)
                img:SetSize(thumbW, thumbH)
                img:SetImage("../" .. bgPath)
                img:SetMouseInputEnabled(false)
                btn.thumbImage = img
            end
        end

        btn.Paint = function(s, w, h)
            local bgCol = COLOR_MAP_BG

            if s.flashCol then
                bgCol = s.flashCol
            elseif s.isWinner then
                bgCol = COLOR_MAP_WINNER
            elseif self.myVote == s.mapID then
                bgCol = COLOR_MAP_VOTED
            elseif s:IsHovered() then
                bgCol = COLOR_MAP_HOVER
            end

            -- Card background
            draw.RoundedBox(6, 0, 0, w, h, bgCol)

            -- Thumbnail area (Material-based)
            local tw = w - cardPad * 2

            if s.thumbMat and s.thumbMat ~= false then
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(s.thumbMat)
                surface.DrawTexturedRect(cardPad, cardPad, tw, thumbH)
            elseif not s.thumbImage then
                -- No thumbnail at all — draw placeholder
                draw.RoundedBox(4, cardPad, cardPad, tw, thumbH, COLOR_NO_THUMB)
                draw.SimpleText(
                    string.upper(s.mapName),
                    "EFT_MapVoteName",
                    cardPad + tw / 2, cardPad + thumbH / 2,
                    Color(150, 150, 170, 200),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
                )
            end
            -- If thumbImage exists, the DImage child draws itself automatically

            -- Map name text below thumbnail
            local textY = cardPad + thumbH + 4
            -- Pretty-print the map name: strip prefix and version, capitalize
            local displayName = s.mapName:gsub("^eft_", ""):gsub("^xft_", "")
            displayName = displayName:gsub("_v%d+$", ""):gsub("_b%d+$", ""):gsub("_r%d+$", ""):gsub("%d+r%d+$", "")
            displayName = displayName:gsub("_", " ")
            -- Title case
            displayName = displayName:gsub("(%a)([%w_']*)", function(first, rest)
                return first:upper() .. rest:lower()
            end)

            draw.SimpleText(
                displayName,
                "EFT_MapVoteName",
                w / 2, textY,
                COLOR_WHITE,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
            )

            -- Vote count badge (top-right corner of thumbnail)
            if s.voteCount > 0 then
                local badge = tostring(s.voteCount)
                surface.SetFont("EFT_MapVoteCount")
                local badgeW = surface.GetTextSize(badge)
                local badgeX = w - cardPad - 4
                local badgeY = cardPad + 4

                draw.RoundedBox(10, badgeX - badgeW - 10, badgeY - 2, badgeW + 16, 24, Color(0, 0, 0, 180))
                draw.SimpleText(badge, "EFT_MapVoteCount", badgeX - 2, badgeY, COLOR_VOTES, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
        end

        btn.DoClick = function(s)
            if self.winnerID then return end -- Voting is over
            self.myVote = s.mapID

            net.Start("EFT_MapVoteUpdate")
                net.WriteUInt(MapVote.UPDATE_VOTE, 3)
                net.WriteUInt(s.mapID, 32)
            net.SendToServer()

            surface.PlaySound("garrysmod/ui_click.wav")
        end

        self.mapButtons[i] = btn
    end

    -- Size the canvas
    local totalH = 40 + rows * (cardH + gridPad)
    canvas:SetTall(totalH)
end

function PANEL:UpdateVotes()
    -- Count votes per map
    local counts = {}
    for _, mapIdx in pairs(MapVote.Votes) do
        counts[mapIdx] = (counts[mapIdx] or 0) + 1
    end

    for i, btn in ipairs(self.mapButtons) do
        if IsValid(btn) then
            btn.voteCount = counts[i] or 0
        end
    end
end

function PANEL:ShowWinner(winnerID)
    self.winnerID = winnerID
    self:SetVisible(true)

    -- Update votes one last time
    self:UpdateVotes()

    local btn = self.mapButtons[winnerID]
    if not IsValid(btn) then return end

    -- Scroll the winner into view
    if IsValid(self.scrollPanel) then
        self.scrollPanel:ScrollToChild(btn)
    end

    -- Flash animation
    local flashTimes = {
        {0.0, true},
        {0.2, false},
        {0.4, true},
        {0.6, false},
        {0.8, true},
        {1.0, false},
        {1.2, true},
    }

    for _, ft in ipairs(flashTimes) do
        local delay, on = ft[1], ft[2]
        timer.Simple(delay, function()
            if not IsValid(btn) then return end
            if on then
                btn.flashCol = Color(0, 255, 200, 255)
                surface.PlaySound("hl1/fvox/blip.wav")
            else
                btn.flashCol = nil
            end
        end)
    end

    -- Set as winner after flash
    timer.Simple(1.4, function()
        if not IsValid(btn) then return end
        btn.isWinner = true
        btn.flashCol = nil
    end)
end

function PANEL:Paint(w, h)
    -- Dark overlay
    surface.SetDrawColor(COLOR_BG)
    surface.DrawRect(0, 0, w, h)

    -- Header bar
    draw.RoundedBoxEx(0, 0, 0, w, 72, COLOR_HEADER, false, false, false, false)

    -- Title
    draw.SimpleText(
        "VOTE FOR NEXT MAP",
        "EFT_MapVoteTitle",
        w / 2, 20,
        COLOR_WHITE,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
    )

    -- Countdown or winner display
    if not self.winnerID then
        local timeLeft = math.max(0, math.ceil(MapVote.EndTime - CurTime()))
        local countCol = timeLeft <= 5 and COLOR_COUNTDOWN or COLOR_WHITE
        draw.SimpleText(
            tostring(timeLeft) .. "s",
            "EFT_MapVoteCountdown",
            w - 30, 20,
            countCol,
            TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP
        )
    else
        local winnerName = MapVote.CurrentMaps[self.winnerID] or "???"
        draw.SimpleText(
            "WINNER: " .. winnerName,
            "EFT_MapVoteCountdown",
            w / 2, 46,
            COLOR_MAP_WINNER,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
        )
    end
end

function PANEL:Think()
    -- Nothing needed; voting state is managed by net handlers
end

derma.DefineControl("EFT_MapVoteScreen", "EFT Map Vote Screen", PANEL, "DPanel")
