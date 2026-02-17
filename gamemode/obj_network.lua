/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity - Foundation)
-- gamemode/obj_network.lua
-- OOP Networking Wrapper for EFT
-- Mimics s&box RPCs / Networked properties
-- See lib/SBOX_MAPPING.lua for full porting reference.
--
-- s&box mapping:
--   Network:RPC("name", recipients, ...)  → [Rpc.Broadcast] method + Rpc.FilterInclude(conn)
--   Network:RPC("name", nil, ...)         → [Rpc.Host] method (client → server)
--   net.Start/Send/Broadcast              → replaced entirely by [Rpc.*] attributes
--   net.WriteString/Float/etc             → automatic serialization via C# method parameters
--   SetGlobalBool/Int/Float               → [Sync(SyncFlags.FromHost)] properties
--   NWVar                                 → [Sync] properties on components
--
-- Bandwidth monitoring tracks bytes/messages per net string for profiling.

---@class NetworkStats
---@field messages number Total messages sent for this net string
---@field bytes number Total estimated bytes sent for this net string
---@field lastSent number CurTime() of last send

---@class Network : BaseObject
---@field _stats table<string, NetworkStats> Per-message-name bandwidth tracking (SERVER only)
---@field _totalBytes number Total bytes sent across all messages
---@field _totalMessages number Total messages sent
---@field _windowStart number CurTime() when current tracking window started
Network = class("Network")

--- Initialize the Network wrapper with bandwidth tracking.
function Network:ctor()
    self._stats = {}
    self._totalBytes = 0
    self._totalMessages = 0
    self._windowStart = CurTime and CurTime() or 0

end

-- ============================================================================
-- SERIALIZATION HELPERS (shared between SERVER and CLIENT)
-- ============================================================================

--- Estimate the byte size of a value for bandwidth tracking.
---@param v any The value to estimate
---@return number bytes Estimated byte size
local function EstimateArgSize(v)
    local t = type(v)
    if t == "string" then return #v + 2       -- length prefix + string data
    elseif t == "number" then return 4         -- float32
    elseif t == "boolean" then return 1        -- 1 bit rounded up
    elseif t == "Entity" or t == "Player" then return 2 -- entity index (uint16)
    elseif t == "Vector" then return 12        -- 3x float32
    elseif t == "Angle" then return 12         -- 3x float32
    elseif t == "table" then return 64         -- rough estimate for net.WriteTable
    end
    return 0
end

--- Write a value to the net buffer using auto-type detection.
--- Maps to: C# serialized RPC parameter encoding
---@param v any The value to serialize
local function WriteArg(v)
    local t = type(v)
    if t == "string" then net.WriteString(v)
    elseif t == "number" then net.WriteFloat(v)
    elseif t == "boolean" then net.WriteBool(v)
    elseif t == "Entity" or t == "Player" then net.WriteEntity(v)
    elseif t == "Vector" then net.WriteVector(v)
    elseif t == "Angle" then net.WriteAngle(v)
    elseif t == "table" then net.WriteTable(v) -- Expensive! Prefer typed writers.
    end
end

-- ============================================================================
-- RPC (Remote Procedure Call)
-- ============================================================================

--- Send a networked message with auto-serialized arguments.
--- SERVER: sends to recipients (or broadcasts if nil).
--- CLIENT: sends to server (recipients parameter is ignored, treated as first arg).
---
--- Maps to: C# `[Broadcast] void MethodName(args)` or `Rpc.Call("method", args)`
---@param name string Net message name (must be registered with util.AddNetworkString)
---@param recipients? Player|table|nil SERVER: target player(s), nil = broadcast. CLIENT: ignored (first data arg).
---@param ... any Additional arguments to serialize and send
function Network:RPC(name, recipients, ...)
    local args = {...}
    local byteEstimate = 2 -- net message header overhead

    if SERVER then
        net.Start(name)
        for _, arg in ipairs(args) do
            WriteArg(arg)
            byteEstimate = byteEstimate + EstimateArgSize(arg)
        end

        if recipients then
            net.Send(recipients)
        else
            net.Broadcast()
        end
    else
        -- CLIENT → SERVER: recipients param is meaningless, fold it into args
        net.Start(name)
        if recipients ~= nil then
            WriteArg(recipients)
            byteEstimate = byteEstimate + EstimateArgSize(recipients)
        end
        for _, arg in ipairs(args) do
            WriteArg(arg)
            byteEstimate = byteEstimate + EstimateArgSize(arg)
        end
        net.SendToServer()
    end

    -- Track bandwidth
    self:_recordSend(name, byteEstimate)
end

-- ============================================================================
-- TYPED WRITERS (for precise control when auto-detect isn't sufficient)
-- Maps to: C# explicit parameter types in RPC signatures
-- ============================================================================

---@param name string Net message name to start
function Network:Start(name) net.Start(name) end

---@param i number Integer value
---@param bits? number Bit count (default 32)
function Network:WriteInt(i, bits) net.WriteInt(i, bits or 32) end

---@param i number Unsigned integer value
---@param bits? number Bit count (default 32)
function Network:WriteUInt(i, bits) net.WriteUInt(i, bits or 32) end

---@param f number Float value
function Network:WriteFloat(f) net.WriteFloat(f) end

---@param s string String value
function Network:WriteString(s) net.WriteString(s) end

---@param e Entity Entity reference
function Network:WriteEntity(e) net.WriteEntity(e) end

---@param b boolean Boolean value
function Network:WriteBool(b) net.WriteBool(b) end

--- Broadcast current net message to all clients (SERVER only).
function Network:Broadcast() net.Broadcast() end

--- Send current net message to specific player(s) (SERVER only).
---@param ply Player|table Target player or table of players
function Network:Send(ply) net.Send(ply) end

--- Send current net message to server (CLIENT only).
function Network:SendToServer() net.SendToServer() end

-- ============================================================================
-- BANDWIDTH MONITORING
-- Maps to: C# diagnostic/telemetry system for network profiling
-- ============================================================================

--- Record a send event for bandwidth tracking.
---@param name string Net message name
---@param bytes number Estimated bytes sent
---@private
function Network:_recordSend(name, bytes)
    if not self._stats[name] then
        self._stats[name] = { messages = 0, bytes = 0, lastSent = 0 }
    end
    local stat = self._stats[name]
    stat.messages = stat.messages + 1
    stat.bytes = stat.bytes + bytes
    stat.lastSent = CurTime()

    self._totalBytes = self._totalBytes + bytes
    self._totalMessages = self._totalMessages + 1
end

--- Get bandwidth stats for a specific net message.
---@param name string Net message name
---@return NetworkStats? stats Stats table or nil if never sent
function Network:GetStats(name)
    return self._stats[name]
end

--- Get all bandwidth stats, sorted by total bytes descending.
---@return table[] stats Array of {name, messages, bytes, lastSent}
function Network:GetAllStats()
    local result = {}
    for name, stat in pairs(self._stats) do
        result[#result + 1] = {
            name = name,
            messages = stat.messages,
            bytes = stat.bytes,
            lastSent = stat.lastSent,
        }
    end
    table.sort(result, function(a, b) return a.bytes > b.bytes end)
    return result
end

--- Get total bytes and messages sent since tracking started.
---@return number totalBytes
---@return number totalMessages
---@return number windowSeconds Seconds since tracking started
function Network:GetTotals()
    return self._totalBytes, self._totalMessages, CurTime() - self._windowStart
end

--- Reset all bandwidth tracking counters.
function Network:ResetStats()
    self._stats = {}
    self._totalBytes = 0
    self._totalMessages = 0
    self._windowStart = CurTime()
end

--- Print a formatted bandwidth report to console.
--- Maps to: developer console profiling output
function Network:PrintStats()
    local totalBytes, totalMessages, windowSec = self:GetTotals()
    print(string.format("\n=== Network Stats (%.1fs window) ===", windowSec))
    print(string.format("Total: %d messages, %.1f KB", totalMessages, totalBytes / 1024))
    if windowSec > 0 then
        print(string.format("Rate: %.1f msg/s, %.2f KB/s", totalMessages / windowSec, totalBytes / 1024 / windowSec))
    end
    print("---")
    local stats = self:GetAllStats()
    for i, s in ipairs(stats) do
        if i > 20 then print("... and " .. (#stats - 20) .. " more") break end
        print(string.format("  %-30s %5d msgs  %8.1f KB", s.name, s.messages, s.bytes / 1024))
    end
    print("===\n")
end

-- Static instance
if not GlobalNetwork then GlobalNetwork = Network() end

-- Console command for quick bandwidth check
if SERVER then
    concommand.Add("eft_netstats", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        GlobalNetwork:PrintStats()
    end)

    concommand.Add("eft_netstats_reset", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        GlobalNetwork:ResetStats()
        print("[Network] Stats reset.")
    end)
end
