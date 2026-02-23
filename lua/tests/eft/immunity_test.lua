-- EFT PlayerController Immunity Tests
-- Tests knockdown and charge immunity tracking (pure table logic on self.ply).
-- Creates a mock controller that inherits PlayerController methods without calling ctor,
-- so the real singleton is never touched and tests are fully isolated.

local function makeCtrl()
    local mockPly = { m_KnockdownImmunity = {}, m_ChargeImmunity = {} }
    return setmetatable({ ply = mockPly }, PlayerController)
end

return {
    groupName = "PlayerController Immunity",
    cases = {

        -- ---- Knockdown immunity ----
        {
            name = "GetKnockdownImmunity: returns 0 for unknown key",
            func = function()
                local ctrl = makeCtrl()
                expect(ctrl:GetKnockdownImmunity("somekey")).to.equal(0)
            end,
        },
        {
            name = "SetKnockdownImmunity then GetKnockdownImmunity returns stored value",
            func = function()
                local ctrl = makeCtrl()
                ctrl:SetKnockdownImmunity("player_a", 999)
                expect(ctrl:GetKnockdownImmunity("player_a")).to.equal(999)
            end,
        },
        {
            name = "SetKnockdownImmunity: keys are independent",
            func = function()
                local ctrl = makeCtrl()
                ctrl:SetKnockdownImmunity("a", 100)
                ctrl:SetKnockdownImmunity("b", 200)
                expect(ctrl:GetKnockdownImmunity("a")).to.equal(100)
                expect(ctrl:GetKnockdownImmunity("b")).to.equal(200)
            end,
        },
        {
            name = "SetKnockdownImmunity: overwrite updates value",
            func = function()
                local ctrl = makeCtrl()
                ctrl:SetKnockdownImmunity("a", 100)
                ctrl:SetKnockdownImmunity("a", 500)
                expect(ctrl:GetKnockdownImmunity("a")).to.equal(500)
            end,
        },
        {
            name = "ResetKnockdownImmunity: stores CurTime() + 2",
            func = function()
                local ctrl = makeCtrl()
                local before = CurTime()
                ctrl:ResetKnockdownImmunity("a")
                local after = CurTime()
                local stored = ctrl:GetKnockdownImmunity("a")
                expect(stored >= before + 2).to.beTrue()
                expect(stored <= after + 2).to.beTrue()
            end,
        },
        {
            name = "Knockdown immunity: separate controllers don't share state",
            func = function()
                local ctrl1 = makeCtrl()
                local ctrl2 = makeCtrl()
                ctrl1:SetKnockdownImmunity("a", 777)
                expect(ctrl2:GetKnockdownImmunity("a")).to.equal(0)
            end,
        },

        -- ---- Charge immunity ----
        {
            name = "GetChargeImmunity: returns 0 for unknown key",
            func = function()
                local ctrl = makeCtrl()
                expect(ctrl:GetChargeImmunity("somekey")).to.equal(0)
            end,
        },
        {
            name = "SetChargeImmunity then GetChargeImmunity returns stored value",
            func = function()
                local ctrl = makeCtrl()
                ctrl:SetChargeImmunity("player_a", 500)
                expect(ctrl:GetChargeImmunity("player_a")).to.equal(500)
            end,
        },
        {
            name = "SetChargeImmunity: keys are independent",
            func = function()
                local ctrl = makeCtrl()
                ctrl:SetChargeImmunity("a", 11)
                ctrl:SetChargeImmunity("b", 22)
                expect(ctrl:GetChargeImmunity("a")).to.equal(11)
                expect(ctrl:GetChargeImmunity("b")).to.equal(22)
            end,
        },
        {
            name = "ResetChargeImmunity: stores CurTime() + 0.45",
            func = function()
                local ctrl = makeCtrl()
                local before = CurTime()
                ctrl:ResetChargeImmunity("a")
                local after = CurTime()
                local stored = ctrl:GetChargeImmunity("a")
                expect(stored >= before + 0.45).to.beTrue()
                expect(stored <= after + 0.45).to.beTrue()
            end,
        },

        -- ---- Cross-immunity independence ----
        {
            name = "Knockdown and charge immunity tables are independent",
            func = function()
                local ctrl = makeCtrl()
                ctrl:SetKnockdownImmunity("a", 111)
                ctrl:SetChargeImmunity("a", 222)
                expect(ctrl:GetKnockdownImmunity("a")).to.equal(111)
                expect(ctrl:GetChargeImmunity("a")).to.equal(222)
            end,
        },
    },
}
