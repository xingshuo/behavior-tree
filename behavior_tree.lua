local Coroutines = require("coroutines")
local Env = require("env")

local bret = {
	FAIL	= "FAIL",
	SUCCESS = "SUCCESS",
	RUNNING = "RUNNING",
	ABORT   = "ABORT",
}


function NewIfElseNode(env, nodeData)
	local children = {}
	for i, childData in ipairs(nodeData.children) do
		children[i] = GenerateNode(env, childData)
	end
	return function ()
		if children[1]() == bret.SUCCESS then
			return children[2]()
		end
		local child = children[3]
		if not child then
			return bret.FAIL
		end
		return child()
	end
end

function NewParallelNode(env, nodeData)
	local children = {}
	for i, childData in ipairs(nodeData.children) do
		children[i] = GenerateNode(env, childData)
	end
	return function ()
		for _, child in ipairs(children) do
			child()
		end
		return bret.SUCCESS
	end
end

function NewSelectorNode(env, nodeData)
	local children = {}
	for i, childData in ipairs(nodeData.children) do
		children[i] = GenerateNode(env, childData)
	end
	return function ()
		for _, child in ipairs(children) do
			if child() == bret.SUCCESS then
				return bret.SUCCESS
			end
		end
		return bret.FAIL
	end
end

function NewSequenceNode(env, nodeData)
	local children = {}
	for i, childData in ipairs(nodeData.children) do
		children[i] = GenerateNode(env, childData)
	end
	return function ()
		for _, child in ipairs(children) do
			if child() == bret.FAIL then
				return bret.FAIL
			end
		end
		return bret.SUCCESS
	end
end

local function runCode(env, code)
	code = code:gsub("!=", "~=")
	local func = load("return function(vars, math) _ENV = vars return " .. code .. " end")()
	return func(env.vars, math)
end

function NewCheckNode(env, nodeData)
	return function ()
		if not nodeData.args then
			return bret.FAIL
		end
		local code = nodeData.args["value"]
		if not code then
			return bret.FAIL
		end
		return runCode(env, code) and bret.SUCCESS or bret.FAIL
	end
end

local function ret(r)
	return r and bret.SUCCESS or bret.FAIL
end

function NewCmpNode(env, nodeData)
	return function ()
		local args = nodeData.args
		local code = args["value"]
		local value = runCode(env, code)
		assert(type(value) == 'number')
		if args.gt then
			return ret(value > args.gt)
		elseif args.ge then
			return ret(value >= args.ge)
		elseif args.eq then
			return ret(value == args.eq)
		elseif args.lt then
			return ret(value < args.lt)
		elseif args.le then
			return ret(value <= args.le)
		else
			error('args error')
		end
	end
end

function NewRepeatNode(env, nodeData)
	local child = GenerateNode(env, nodeData.children[1])
	return function ()
		local args = nodeData.args
		local count = args.count
		for i = 1, count do
			if child() == bret.FAIL then
				return bret.FAIL
			end
		end
		return bret.SUCCESS
	end
end

function NewRepeatUntilSuccessNode(env, nodeData)
	local child = GenerateNode(env, nodeData.children[1])
	return function ()
		local args = nodeData.args
		local maxLoop = args.maxLoop
		for i = 1, maxLoop do
			if child() == bret.SUCCESS then
				return bret.SUCCESS
			end
			if i < maxLoop then
				Coroutines.Yield(bret.RUNNING)
			end
		end
		return bret.FAIL
	end
end

function NewRepeatUntilFailureNode(env, nodeData)
	local child = GenerateNode(env, nodeData.children[1])
	return function ()
		local args = nodeData.args
		local maxLoop = args.maxLoop
		for i = 1, maxLoop do
			if child() == bret.FAIL then
				return bret.SUCCESS
			end
			if i < maxLoop then
				Coroutines.Yield(bret.RUNNING)
			end
		end
		return bret.FAIL
	end
end


function NewWaitNode(env, nodeData)
	return function ()
		local args = nodeData.args
		local endTime = env.ctx.time + args.time
		if env.ctx.time >= endTime then
			return bret.SUCCESS
		end
		Coroutines.Yield(bret.RUNNING)
	end
end

function NewLogNode(env, nodeData)
	return function ()
		local args = nodeData.args
		print(args.message)
		return bret.SUCCESS
	end
end


local GeneratorMap = {
	-- Composite Node
	IfElse = NewIfElseNode,
	Parallel = NewParallelNode,
	Selector = NewSelectorNode,
	Sequence = NewSequenceNode,

	-- Condition Nodes
	Check = NewCheckNode,
	Cmp = NewCmpNode,

	-- Decorator Nodes
	Repeat = NewRepeatNode,
	RepeatUntilSuccess = NewRepeatUntilSuccessNode,
	RepeatUntilFailure = NewRepeatUntilFailureNode,

	-- Action Nodes
	Wait = NewWaitNode,
	Log = NewLogNode,
}

function GenerateNode(env, nodeData)
	local generator = assert(GeneratorMap[nodeData.name], nodeData.name)
	return generator(env, nodeData)
end

function NewTree(treeData)
	local tree = {}
	tree.env = Env.New({tree = tree, ctx = {time = 0}})
	tree.root = GenerateNode(tree.env, treeData.root)
	return tree
end