local Node = require("behavior_node")
local Env = require("env")
local Coroutines = require("coroutines")
local Const = require("const")

local bret = Const.bret
local btree_event = Const.btree_event
local traceback = debug.traceback
local tostring = tostring

local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

function BehaviorTree.New(treeData, ctx)
	local o = {}
	setmetatable(o, BehaviorTree)
	o:init(treeData, ctx)
	return o
end

function BehaviorTree:init(treeData, ctx)
	self.env = Env.New({tree = self, ctx = ctx})
	self.root = Node.GenerateNode(self.env, treeData.root)
	self.runStack = nil
	self.runningNow = false
end

function BehaviorTree:Run()
	self.runningNow = true
	local co = self.runStack
	if co == nil then
		co = Coroutines.Create(self.root)
		self.runStack = co
		self:Dispatch(btree_event.BEFORE_RUN)
	end
	local ok, ret = coroutine.resume(co)
	if not ok then -- 运行错误，下一次从根节点重新执行
		self.runStack = nil
		self.env:ClearInnerVars()
		local tb = traceback(co,tostring(ret))
		if coroutine.close then -- above lua 5.4
			coroutine.close(co)
		end
		self.runningNow = false
		print("[ERROR]: btree run err")
		error(tb)
	end
	if self.env.abort then
		self.env.abort = nil
		self.runStack = nil
		self.env:ClearInnerVars()
		self:Dispatch(btree_event.INTERRUPTED)
		print("[WARN]: btree run abort")
		self.runningNow = false
		return bret.ABORT
	elseif ret == bret.SUCCESS then
		self.runStack = nil
		self:Dispatch(btree_event.AFTER_RUN)
		self:Dispatch(btree_event.AFTER_RUN_SUCCESS)
	elseif ret == bret.FAIL then
		self.runStack = nil
		self:Dispatch(btree_event.AFTER_RUN)
		self:Dispatch(btree_event.AFTER_RUN_FAILURE)
	end
	self.runningNow = false
	print("[INFO]: btree run result: ", ret)
	return ret
end

function BehaviorTree:Yield()
	if self.env.abort then
		return true
	end
	Coroutines.Yield(bret.RUNNING)
	if self.env.abort then
		return true
	end
end

function BehaviorTree:Dispatch(event, ...)
	print("[INFO]: dispatch event: ", event, "args: ", ...)
end

-- 返回行为树运行状态，而非是否处于BehaviorTree:Run()中
function BehaviorTree:IsRunning()
	return self.runStack ~= nil
end

function BehaviorTree:Interrupt()
	-- 行为树内部只能通过return bret.ABORT来实现打断
	assert(not self.runningNow)
	if self.runStack ~= nil then
		self.env.abort = true
		self:Run()
	end
end

local M = {}

function M.NewTree(treeData, ctx)
	return BehaviorTree.New(treeData, ctx)
end

return M