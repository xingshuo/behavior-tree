local BehaviorEnv = {}
BehaviorEnv.__index = BehaviorEnv

function BehaviorEnv.New(vars)
    local o = {}
    setmetatable(o, BehaviorEnv)
    o:init(vars)
    return o
end

function BehaviorEnv:init(vars)
    for k, v in pairs(vars) do
        self[k] = v
    end
    self.innerVars = {}
end

function BehaviorEnv:SetVar(k, v)
    self.innerVars[k] = v
end

function BehaviorEnv:GetVar(k)
    return self.innerVars[k]
end

return BehaviorEnv