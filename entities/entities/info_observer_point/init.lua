-- Stub entity to suppress "Attempted to create unknown entity type info_observer_point" errors.
-- These are placed in Hammer for spectator camera positions but don't need any logic.
AddCSLuaFile()
ENT.Type = "point"
ENT.Base = "base_point"

function ENT:Initialize()
end
