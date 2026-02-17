-- gamemode/lib/class.lua
/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity - Foundation)
-- Standardized OOP for GMod → s&box parity
-- Maps to: C# class inheritance, virtual methods, is/as operators
--
-- GMod usage:  MyClass = class("MyClass", BaseClass)
-- s&box equiv: public class MyClass : BaseClass { }

---@alias ClassTable table

---@class BaseObject
---@field ClassName string Human-readable class name (maps to C# nameof())
---@field BaseClass? BaseObject Parent class prototype (maps to C# base)
---@field __index table Metatable self-index for prototype chain

local _registry = {} ---@type table<string, BaseObject>

--- Define a new class with optional single inheritance.
--- Maps to: `public class {name} : {base} { }`
---@param name string Class name (unique, used for Is() lookups and debugging)
---@param base? BaseObject Optional base class to inherit from
---@return BaseObject cls The new class table (also callable as constructor)
function class(name, base)
    local cls = {}

    -- Set name for debugging/type checking
    cls.ClassName = name

    -- Prototype-based inheritance
    if base then
        setmetatable(cls, { __index = base })
        cls.BaseClass = base
    end

    -- Set index to self so instances can look up methods
    cls.__index = cls

    -- Constructor call: MyClass() -> MyClass:ctor()
    -- Maps to: C# `new MyClass(...)` → `ctor(...)` method
    setmetatable(cls, {
        __call = function(c, ...)
            local instance = setmetatable({}, c)
            if instance.ctor then
                instance:ctor(...)
            end
            return instance
        end
    })

    --- Type-check: is this instance of the given class?
    --- Maps to: C# `instance is TypeName`
    ---@param typeOrName string|BaseObject Class name string or class table reference
    ---@return boolean
    function cls:Is(typeOrName)
        if type(typeOrName) == "string" then
            return self.ClassName == typeOrName or (self.BaseClass and self.BaseClass:Is(typeOrName))
        else
            return self == typeOrName or (self.BaseClass and self.BaseClass:Is(typeOrName))
        end
    end

    _registry[name] = cls
    return cls
end

--- Retrieve a registered class by name.
--- Maps to: C# `Type.GetType(name)` / reflection lookup
---@param name string The class name to look up
---@return BaseObject? cls The class table, or nil if not found
function GetClass(name)
    return _registry[name]
end
