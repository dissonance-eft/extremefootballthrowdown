/*
/// MANIFEST LINKS:
/// Principles: P-090 (Death Consequence), C-010 (Continuous Participation)
	Start of the death message stuff.
*/

include( 'vgui/vgui_gamenotice.lua' )

local function CreateDeathNotify()
	-- Death/possession notices disabled for EFT.
	-- The top-right notice panel creates visual noise that doesn't fit the sport genre.
	-- All AddDeathNotice/AddPlayerAction calls safely no-op because g_DeathNotify is nil.
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
