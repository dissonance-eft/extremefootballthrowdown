
-- Round result and InRound state are owned by GameManager (single writer).
-- These GM:* wrappers delegate to GAMEMANAGER for backward compat with hook.Add callers.
function GM:SetRoundWinner( ply, resulttext ) GAMEMANAGER:SetRoundWinner(ply, resulttext) end
function GM:SetRoundResult( i, resulttext ) GAMEMANAGER:SetRoundResult(i, resulttext) end
function GM:ClearRoundResult() GAMEMANAGER:ClearRoundResult() end
function GM:SetInRound( b ) GAMEMANAGER:SetInRound(b) end
function GM:InRound() return GetGlobalBool( "InRound", false ) end

function GM:OnRoundStart( num )

	UTIL_UnFreezeAllPlayers()

end

function GM:OnRoundEnd( num )
end

function GM:OnRoundResult( result, resulttext )

	// The fact that result might not be a team 
	// shouldn't matter when calling this..
	team.AddScore( result, 1 )

end

function GM:OnRoundWinner( ply, resulttext )

	// Do whatever you want to do with the winner here (this is only called in Free For All gamemodes)...
	ply:AddFrags( 1 )

end

function GM:OnPreRoundStart( num )

	game.CleanUpMap()
	
	UTIL_StripAllPlayers()
	UTIL_SpawnAllPlayers()
	UTIL_FreezeAllPlayers()

end

function GM:CanStartRound( iNum )
	return true
end

function GM:StartRoundBasedGame()
	
	GAMEMODE:PreRoundStart( 1 )
	
end

// Number of rounds
function GM:GetRoundLimit()
	return GAMEMODE.RoundLimit;
end

// Round/score limit check is now owned by GameManager
function GM:HasReachedRoundLimit( iNum )
	return GAMEMANAGER:HasReachedRoundLimit(iNum)
end

// This is for the timer-based game end. set this to return true if you want it to end mid-round
function GM:CanEndRoundBasedGame()
	return false
end

// You can add round time by calling this (takes time in seconds)
function GM:AddRoundTime( fAddedTime )

	if( !GAMEMODE:InRound() ) then // don't add time if round is not in progress
		return
	end

	-- Update the canonical round end time (GameManager owns "RoundEndsAt")
	local newEnd = GetGlobalFloat( "RoundEndsAt", CurTime() ) + fAddedTime
	SetGlobalFloat( "RoundEndsAt", newEnd )
	-- Legacy compat: also update RoundEndTime for any code reading it
	SetGlobalFloat( "RoundEndTime", newEnd )

	net.Start( "RoundAddedTime" )
		net.WriteFloat( fAddedTime )
	net.Broadcast()

end

// This gets the timer for a round (you can make round number dependant round lengths, or make it cvar controlled)
function GM:GetRoundTime( iRoundNumber )
	return GAMEMODE.RoundLength -- Fixed 15 minute round duration
end

//
// Internal, override OnPreRoundStart if you want to do stuff here
//
function GM:PreRoundStart( iNum )
	GAMEMANAGER:PreRoundStart(iNum)
end

//
// Internal, override OnRoundStart if you want to do stuff here
//
function GM:RoundStart()
	GAMEMANAGER:RoundStart()
end

// Result formatting is now owned by GameManager
function GM:ProcessResultText( result, resulttext )
	return GAMEMANAGER:ProcessResultText(result, resulttext)
end

//
// Round Ended with Result
//
function GM:RoundEndWithResult( result, resulttext )
	GAMEMANAGER:RoundEndWithResult(result, resulttext)
end

//
// Internal, override OnRoundEnd if you want to do stuff here
//
function GM:RoundEnd()
	GAMEMANAGER:RoundEnd()
end

function GM:GetTeamAliveCounts()

	local TeamCounter = {}

	for k,v in pairs( player.GetAll() ) do
		if ( v:Alive() && v:Team() > 0 && v:Team() < 1000 ) then
			TeamCounter[ v:Team() ] = TeamCounter[ v:Team() ] or 0
			TeamCounter[ v:Team() ] = TeamCounter[ v:Team() ] + 1
		end
	end

	return TeamCounter

end

//
// For round based games that end when a team is dead
//
function GM:CheckPlayerDeathRoundEnd()

	if ( !GAMEMODE.RoundBased ) then return end
	if ( !GAMEMODE:InRound() ) then return end

	if ( GAMEMODE.RoundEndsWhenOneTeamAlive ) then
	
		local Teams = GAMEMODE:GetTeamAliveCounts()

		if ( table.Count( Teams ) == 0 ) then
		
			GAMEMODE:RoundEndWithResult( 1001, "Draw, everyone loses!" )
			return
			
		end
	
		if ( table.Count( Teams ) == 1 ) then
		
			local TeamID = table.GetFirstKey( Teams )
			GAMEMODE:RoundEndWithResult( TeamID )
			return
			
		end
		
	end

	
end

hook.Add( "PlayerDisconnected", "RoundCheck_PlayerDisconnect", function() timer.Simple( 0.2, function() GAMEMODE:CheckPlayerDeathRoundEnd() end ) end )
hook.Add( "PostPlayerDeath", "RoundCheck_PostPlayerDeath", function() timer.Simple( 0.2, function() GAMEMODE:CheckPlayerDeathRoundEnd() end ) end )

//
// You should use this to check any round end conditions 
//
function GM:CheckRoundEnd()

	// Do checks.. 
	
	// if something then call GAMEMODE:RoundEndWithResult( TEAM_BLUE, "Team Blue Ate All The Mushrooms!" )
	// OR for a free for all you could do something like... GAMEMODE:RoundEndWithResult( SomePlayer )

end

function GM:CheckRoundEndInternal()

	if ( !GAMEMODE:InRound() ) then return end

	GAMEMODE:CheckRoundEnd()
	
	timer.Create( "CheckRoundEnd", 1, 0, function() GAMEMODE:CheckRoundEndInternal() end )

end

//
// This is called when the round time ends.
//
function GM:RoundTimerEnd()
	GAMEMANAGER:RoundTimerEnd()
end

//
// This is called when time runs out and there is no winner chosen yet (free for all gamemodes only)
// By default it chooses the player with the most frags but you can edit this to do what you need..
//
function GM:SelectCurrentlyWinningPlayer()
	
	local winner
	local topscore = 0

	for k,v in pairs( player.GetAll() ) do
	
		if v:Frags() > topscore and v:Team() != TEAM_CONNECTING and v:Team() != TEAM_UNASSIGNED and v:Team() != TEAM_SPECTATOR then
		
			winner = v
			topscore = v:Frags()
		
		end
	
	end
	
	return winner

end
