/*
/// MANIFEST LINKS:
/// Principles: P-090 (Death Consequence), C-010 (Continuous Participation)
	Start of the death message stuff.
*/

include( 'vgui/vgui_gamenotice.lua' )

local hud_deathnotice_time = CreateClientConVar( "hud_deathnotice_time", "6", true, false )
local hud_deathnotice_limit = CreateClientConVar( "hud_deathnotice_limit", "5", true, false )

local function CreateDeathNotify()
	if IsValid(g_DeathNotify) then g_DeathNotify:Remove() end

	local container = vgui.Create("DPanel")
	container:SetSize(300, 4)
	container:SetPos(ScrW() - 310, 10)
	container.Paint = function() end
	container.Entries = {}

	function container:AddItem(pnl)
		pnl.CreatedAt = RealTime()
		table.insert(self.Entries, pnl)
		while #self.Entries > hud_deathnotice_limit:GetInt() do
			local old = table.remove(self.Entries, 1)
			if IsValid(old) then old:Remove() end
		end
		self:InvalidateLayout(true)
	end

	function container:PerformLayout()
		local y = 0
		for _, ent in ipairs(self.Entries) do
			if IsValid(ent) then
				ent:SetPos(self:GetWide() - ent:GetWide(), y)
				y = y + ent:GetTall() + 2
			end
		end
		self:SetTall(math.max(4, y))
	end

	function container:Think()
		local now = RealTime()
		local limit = hud_deathnotice_time:GetFloat()
		local changed = false
		for i = #self.Entries, 1, -1 do
			local ent = self.Entries[i]
			if not IsValid(ent) or (now - ent.CreatedAt) > limit then
				if IsValid(ent) then ent:Remove() end
				table.remove(self.Entries, i)
				changed = true
			end
		end
		if changed then self:InvalidateLayout(true) end
		self:SetPos(ScrW() - 310, 10)
	end

	g_DeathNotify = container
end

hook.Add( "InitPostEntity", "CreateDeathNotify", CreateDeathNotify )

local function RecvPlayerKilledByPlayer( length )

	local victim 	= net.ReadEntity()
	local inflictor	= net.ReadString()
	local attacker 	= net.ReadEntity()

	if ( !IsValid( attacker ) ) then return end
	if ( !IsValid( victim ) ) then return end
	
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker )	
end
	
net.Receive( "PlayerKilledByPlayer", RecvPlayerKilledByPlayer )


local function RecvPlayerKilledSelf( length )

	local victim 	= net.ReadEntity()

	if ( !IsValid( victim ) ) then return end

	GAMEMODE:AddPlayerAction( victim, GAMEMODE.SuicideString )

end
	
net.Receive( "PlayerKilledSelf", RecvPlayerKilledSelf )


local function RecvPlayerKilled( length )

	local victim 	= net.ReadEntity()
	local inflictor	= net.ReadString()
	local attacker 	= "#" .. net.ReadString()

	if ( !IsValid( victim ) ) then return end
			
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker )

end
	
net.Receive( "PlayerKilled", RecvPlayerKilled )

local function RecvPlayerKilledNPC( length )

	local victim 	= "#" .. net.ReadString()
	local inflictor	= net.ReadString()
	local attacker 	= net.ReadEntity()

	if ( !IsValid( attacker ) ) then return end
			
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker )

end
	
net.Receive( "PlayerKilledNPC", RecvPlayerKilledNPC )


local function RecvNPCKilledNPC( length )

	local victim 	= "#" .. net.ReadString()
	local inflictor	= net.ReadString()
	local attacker 	= "#" .. net.ReadString()
		
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker )

end

net.Receive( "NPCKilledNPC", RecvNPCKilledNPC )


/*---------------------------------------------------------
   Name: gamemode:AddDeathNotice( Victim, Weapon, Attacker )
   Desc: Adds an death notice entry
---------------------------------------------------------*/
function GM:AddDeathNotice( victim, inflictor, attacker )

	if ( !IsValid( g_DeathNotify ) ) then return end

	local pnl = vgui.Create( "GameNotice", g_DeathNotify )
	
	pnl:AddText( attacker )
	pnl:AddIcon( inflictor )
	pnl:AddText( victim )
	
	g_DeathNotify:AddItem( pnl )

end

function GM:AddPlayerAction( ... )
	
	if ( !IsValid( g_DeathNotify ) ) then return end

	local pnl = vgui.Create( "GameNotice", g_DeathNotify )

	for k, v in ipairs({...}) do
		pnl:AddText( v )
	end
	
	// The rest of the arguments should be re-thought.
	// Just create the notify and add them instead of trying to fit everything into this function!???
	
	g_DeathNotify:AddItem( pnl )
	
end
