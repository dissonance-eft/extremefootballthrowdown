-- gamemode/lib/event.lua
-- Typed event/delegate system for GMod → s&box parity
-- See lib/SBOX_MAPPING.lua for full porting reference.
--
-- s&box mapping:
--   Event:Add(fn, id)     → implement ISceneEvent<T> interface on component
--   Event:Remove(id)      → remove component or override with empty
--   Event:Invoke(...)     → IMyEvent.Post(x => x.Method(args)) (scene-wide)
--                         → IMyEvent.PostToGameObject(go, x => x.Method(args)) (targeted)
--   Event:Clear()         → no direct equivalent; events are interface-based
--
-- GMod usage:  local OnScore = Event()  OnScore:Add(fn, "myid")  OnScore:Invoke(data)
-- s&box equiv: public interface IScoreEvents : ISceneEvent<IScoreEvents> { void OnScore(int pts); }

---@class EventListener
---@field fn function The callback function
---@field id? string|function Optional unique identifier for removal

---@class Event
---@field listeners EventListener[] Registered listener entries
Event = {}
Event.__index = Event

--- Create a new Event instance.
--- Maps to: C# `event Action OnSomething;` field declaration
---@return Event
function Event:New()
	local o = {}
	setmetatable(o, self)
	o.listeners = {}
	return o
end

--- Subscribe a callback to this event, optionally with an ID for later removal.
--- Maps to: C# `OnSomething += callback;` or `Event.Register("id", callback)`
---@param callback function The function to call when event fires
---@param id? string Optional unique ID (replaces existing listener with same ID)
---@return function? unsubscribe A cleanup function that removes this listener
function Event:Add(callback, id)
	if not callback then return end

	if id then
		self:Remove(id)
	end

	table.insert(self.listeners, {
		fn = callback,
		id = id
	})

	return function()
		self:Remove(id or callback)
	end
end

--- Unsubscribe a listener by its ID or function reference.
--- Maps to: C# `OnSomething -= callback;` or `Event.Unregister("id")`
---@param idOrCallback string|function The ID string or callback reference to remove
---@return boolean removed True if a listener was found and removed
function Event:Remove(idOrCallback)
	for i, listener in ipairs(self.listeners) do
		if listener.id == idOrCallback or listener.fn == idOrCallback then
			table.remove(self.listeners, i)
			return true
		end
	end
	return false
end

--- Fire the event, calling all listeners with the given arguments.
--- Maps to: C# `OnSomething?.Invoke(args)`
---@param ... any Arguments passed to each listener callback
function Event:Invoke(...)
	for _, listener in ipairs(self.listeners) do
		local status, err = pcall(listener.fn, ...)
		if not status then
			ErrorNoHalt("[Event] Error in listener: " .. tostring(err) .. "\n")
		end
	end
end

--- Remove all listeners.
--- Maps to: C# clearing the event invocation list
function Event:Clear()
	self.listeners = {}
end

--- Callable constructor: `local e = Event()` equivalent to `Event:New()`
setmetatable(Event, {
	__call = function(self)
		return self:New()
	end
})
