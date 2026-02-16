local meta = FindMetaTable("Player")
if not meta then return end

local IN_FORWARD = IN_FORWARD
local LocalPlayer = LocalPlayer
-- Helper to get controller
local function GetController(ply)
	if not ply.Controller then ply.Controller = PlayerController(ply) end
	return ply.Controller
end

function meta:CanCharge()
	return GetController(self):CanCharge()
end

function meta:FixModelAngles(velocity)
	GetController(self):FixModelAngles(velocity)
end

function meta:GetStatus(sType)
	return GetController(self):GetStatus(sType)
end

function meta:RemoveAllStatus(bSilent, bInstant)
end

function meta:RemoveStatus(sType, bSilent, bInstant)
	-- Client side status removal is usually handled by networking or automatic entity removal
	-- But if we have client-side logic, delegate it
	GetController(self):RemoveStatus(sType)
end

function meta:GiveStatus(sType, fDie)
	-- Client side usually doesn't give status, but if predicted...
	GetController(self):GiveStatus(sType, fDie)
end

function meta:IsFriend()
	return self.m_IsFriend
end

timer.Create("checkfriend", 5, 0, function()
	-- This probably isn't the fastest function in the world so I cache it.
	for _, pl in pairs(player.GetAll()) do
		pl.m_IsFriend = pl:GetFriendStatus() == "friend"
	end
end)

function meta:EndState(nocallended)
	GetController(self):EndState(nocallended)
end

function meta:ThirdPersonCamera(camerapos, origin, angles, fov, znear, zfar, lerp, right)
	GetController(self):ThirdPersonCamera(camerapos, origin, angles, fov, znear, zfar, lerp, right)
end
