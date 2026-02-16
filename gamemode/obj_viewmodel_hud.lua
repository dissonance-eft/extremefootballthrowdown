-- gamemode/obj_viewmodel_hud.lua
-- HUD ViewModel (MVVM pattern) for EFT
-- Separates HUD data logic from rendering for s&box parity
--
-- Maps to: C# `class HUDViewModel` (data source for Razor UI panels)
-- The ViewModel computes display-ready values; the actual HUD rendering reads from it.

---@class HUDViewModel
---@field Instance HUDViewModel Static singleton reference (VIEWMODEL_HUD)
HUDViewModel = {}
HUDViewModel.__index = HUDViewModel

--- Create a new HUDViewModel instance.
---@return HUDViewModel
function HUDViewModel:New()
	local o = {}
	setmetatable(o, self)
	return o
end

--- Get the round timer as a formatted "MM:SS" string.
---@return string timer Formatted time remaining, or "" if no active timer
function HUDViewModel:GetRoundTimer()
	local roundEnds = GetGlobalFloat("RoundEndsAt", 0)
	if roundEnds <= 0 then return "" end

	local time = math.max(0, roundEnds - CurTime())
	local minutes = math.floor(time / 60)
	local seconds = math.floor(time % 60)

	return string.format("%02d:%02d", minutes, seconds)
end

--- Get the score for a team.
---@param teamId number Team index (TEAM_RED, TEAM_BLUE)
---@return number score Current team score
function HUDViewModel:GetTeamScore(teamId)
	return team.GetScore(teamId)
end

--- Get the display name for a team.
---@param teamId number Team index
---@return string name Team display name
function HUDViewModel:GetTeamName(teamId)
	return team.GetName(teamId)
end

--- Get the color for a team.
---@param teamId number Team index
---@return Color color Team color
function HUDViewModel:GetTeamColor(teamId)
	return team.GetColor(teamId)
end

--- Should the HUD be drawn for the local player?
---@return boolean draw True if the local player is valid and alive
function HUDViewModel:ShouldDrawHUD()
	local ply = LocalPlayer()
	return IsValid(ply) and ply:Alive()
end

--- Get the local player's horizontal speed (z-axis excluded).
---@return number speed Speed in units/second, rounded
function HUDViewModel:GetSpeed()
	local ply = LocalPlayer()
	if not IsValid(ply) then return 0 end
	local vel = ply:GetVelocity()
	vel.z = 0
	return math.Round(vel:Length())
end

--- Get a status text string for the local player's current state.
---@return string status "KNOCKED DOWN!", "CHARGING", or ""
function HUDViewModel:GetStatusText()
	local ply = LocalPlayer()
	if not IsValid(ply) then return "" end

	if ply:GetState() == STATE_KNOCKEDDOWN then
		return "KNOCKED DOWN!"
	elseif ply:GetState() == STATE_CHARGING then
		return "CHARGING"
	end
	return ""
end

-- Static Accessor
if not VIEWMODEL_HUD then VIEWMODEL_HUD = HUDViewModel:New() end
