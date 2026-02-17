-- gamemode/lib/promise.lua
/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity - Foundation)
-- Lightweight Promise/async for GMod → s&box parity
-- See lib/SBOX_MAPPING.lua for full porting reference.
--
-- s&box mapping:
--   Promise.new(executor)  → new TaskCompletionSource<T>() or Task.Run(() => ...)
--   promise:then_(fn)      → await task; fn(result);  (C# async/await replaces chaining)
--   promise:catch(fn)      → try { await task; } catch (Exception e) { fn(e); }
--   Promise.Delay(n)       → await Task.DelaySeconds(n)
--   Promise.all(promises)  → await Task.WhenAll(tasks)
--   Promise.resolve(val)   → Task.FromResult(val)
--   Promise.reject(err)    → Task.FromException(err)
--   Task.Run(fn)           → GameTask.RunInMainThread(fn)
--
-- GMod usage:  Promise.Delay(2):then_(function() print("done") end)
-- s&box equiv: await Task.DelaySeconds(2); Log.Info("done");

---@alias PromiseState 0|1|2 PENDING=0, FULFILLED=1, REJECTED=2

---@class PromiseHandler
---@field onFulfilled? fun(value: any): any
---@field onRejected? fun(reason: any): any
---@field nextPromise Promise

---@class Promise
---@field state PromiseState Current promise state
---@field value any Fulfilled value (when state == FULFILLED)
---@field reason any Rejection reason (when state == REJECTED)
---@field handlers PromiseHandler[] Pending then/catch handlers
Promise = {}
Promise.__index = Promise

-- Enum for state
local PENDING = 0   ---@type PromiseState
local FULFILLED = 1 ---@type PromiseState
local REJECTED = 2  ---@type PromiseState

--- Create a new Promise with an optional executor function.
--- Maps to: C# `new TaskCompletionSource<T>()` or `Task.Run(() => ...)`
---@param executor? fun(resolve: fun(value: any), reject: fun(reason: any)) Executor receiving resolve/reject callbacks
---@return Promise
function Promise.new(executor)
    local self = setmetatable({}, Promise)
    self.state = PENDING
    self.value = nil
    self.reason = nil
    self.handlers = {}

    local function resolve(value)
        if self.state ~= PENDING then return end

        if value and type(value) == "table" and value.then_ then
            -- Handle promise chaining (thenable unwrapping)
            value:then_(resolve, function(r)
                self:reject(r)
            end)
            return
        end

        self.state = FULFILLED
        self.value = value
        self:executeHandlers()
    end

    local function reject(reason)
        if self.state ~= PENDING then return end
        self.state = REJECTED
        self.reason = reason
        self:executeHandlers()
    end

    if executor then
        local status, err = pcall(executor, resolve, reject)
        if not status then
            reject(err)
        end
    end

    return self
end

--- Chain a fulfillment and/or rejection handler.
--- Maps to: C# `task.ContinueWith(...)` or `await` + try/catch
---@param onFulfilled? fun(value: any): any Called when promise resolves
---@param onRejected? fun(reason: any): any Called when promise rejects
---@return Promise nextPromise Chained promise for further composition
function Promise:then_(onFulfilled, onRejected)
    local nextPromise = Promise.new()

    table.insert(self.handlers, {
        onFulfilled = onFulfilled,
        onRejected = onRejected,
        nextPromise = nextPromise
    })

    if self.state ~= PENDING then
        self:executeHandlers()
    end

    return nextPromise
end

--- Chain a rejection handler (sugar for then_(nil, onRejected)).
--- Maps to: C# `catch` block in async/await
---@param onRejected fun(reason: any): any Called when promise rejects
---@return Promise
function Promise:catch(onRejected)
    return self:then_(nil, onRejected)
end

--- Execute all pending handlers (internal). Called when state transitions.
---@private
function Promise:executeHandlers()
    if self.state == PENDING then return end

    local handlers = self.handlers
    self.handlers = {} -- Clear executed handlers

    for _, handler in ipairs(handlers) do
        local callback
        local arg

        if self.state == FULFILLED then
            callback = handler.onFulfilled
            arg = self.value
        else
            callback = handler.onRejected
            arg = self.reason
        end

        local nextPromise = handler.nextPromise

        if callback then
            local status, result = pcall(callback, arg)
            if status then
                nextPromise:resolve(result) -- Chain resolution
            else
                nextPromise:reject(result) -- Chain error
            end
        else
            -- Pass through if no handler
            if self.state == FULFILLED then
                nextPromise:resolve(arg)
            else
                nextPromise:reject(arg)
            end
        end
    end
end

-- ============================================================================
-- STATIC HELPERS — C# Task.* API parity
-- ============================================================================

--- Create an immediately resolved promise.
--- Maps to: C# `Task.FromResult(value)`
---@param value any The value to resolve with
---@return Promise
function Promise.resolve(value)
    return Promise.new(function(resolve) resolve(value) end)
end

--- Create an immediately rejected promise.
--- Maps to: C# `Task.FromException(reason)`
---@param reason any The rejection reason
---@return Promise
function Promise.reject(reason)
    return Promise.new(function(_, reject) reject(reason) end)
end

--- Wait for all promises to resolve (fail-fast on first rejection).
--- Maps to: C# `Task.WhenAll(tasks)`
---@param promises Promise[] Array of promises to wait on
---@return Promise resolves with results array, or rejects with first error
function Promise.all(promises)
    return Promise.new(function(resolve, reject)
        local results = {}
        local remaining = #promises

        if remaining == 0 then
            resolve({})
            return
        end

        for i, p in ipairs(promises) do
            p:then_(function(val)
                results[i] = val
                remaining = remaining - 1
                if remaining == 0 then
                    resolve(results)
                end
            end, function(err)
                reject(err) -- Fail fast
            end)
        end
    end)
end

--- Return a promise that resolves after a delay.
--- Maps to: C# `Task.DelaySeconds(seconds)` / `await Task.Delay(TimeSpan)`
---@param seconds number Delay in seconds
---@return Promise resolves after the delay
function Promise.Delay(seconds)
    return Promise.new(function(resolve)
        timer.Simple(seconds, function()
            resolve()
        end)
    end)
end

-- ============================================================================
-- s&box Task.* aliases for direct porting
-- ============================================================================

---@class Task
---@field Delay fun(seconds: number): Promise  Alias for Promise.Delay
---@field Run fun(fn: function): Promise        Alias for synchronous Task.Run
Task = {}
Task.Delay = Promise.Delay

--- Run a synchronous function as a promise (resolves/rejects immediately).
--- Maps to: C# `Task.Run(() => { ... })`
---@param fn function The function to execute
---@return Promise
Task.Run = function(fn)
    return Promise.new(function(resolve, reject)
        local status, res = pcall(fn)
        if status then resolve(res) else reject(res) end
    end)
end
