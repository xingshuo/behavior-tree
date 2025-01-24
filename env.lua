local BehaviorEnv = {}
BehaviorEnv.__index = BehaviorEnv

function BehaviorEnv.New(vars)
    local o = {}
    setmetatable(o, BehaviorEnv)
    o:init(vars)
    return o
end

function BehaviorEnv:init(params)
    for k, v in pairs(params) do
        self[k] = v
    end
    self.vars = {}
    self.innerVars = {}
end

function BehaviorEnv:SetVar(k, v)
    self.vars[k] = v
end

function BehaviorEnv:GetVar(k)
    return self.vars[k]
end

function BehaviorEnv:SetInnerVar(nodeId, k, v)
    local map = self.innerVars[nodeId]
    if not map then
        map = {}
        self.innerVars[nodeId] = map
    end
    map[k] = v
end

function BehaviorEnv:GetInnerVar(nodeId, k)
    local map = self.innerVars[nodeId]
    if map then
        return map[k]
    end
end

function BehaviorEnv:ClearInnerVars()
    self.innerVars = {}
end

return BehaviorEnv