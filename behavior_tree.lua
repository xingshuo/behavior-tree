local CoPool = require("co_pool")

local bret = {
	FAIL	= "FAIL",
	SUCCESS = "SUCCESS",
	RUNNING = "RUNNING",
	ABORT   = "ABORT",
}


function NewIfElseNode(env, data)
	local funcs = {}
	for i, child in ipairs(data.children) do
		funcs[i] = GenerateNode(env, child)
	end
	return function (env)
		if funcs[1](env) == bret.SUCCESS then
			return funcs[2](env)
		else
			if not funcs[3] then
				return bret.FAIL
			end
			return funcs[3](env)
		end
	end
end

function NewParallelNode(env, data)
	local funcs = {}
	for i, child in ipairs(data.children) do
		funcs[i] = GenerateNode(env, child)
	end
	return function (env)
		for _, func in ipairs(funcs) do
			func(env)
		end
		return bret.SUCCESS
	end
end

function NewSelectorNode(env, data)
	local funcs = {}
	for i, child in ipairs(data.children) do
		funcs[i] = GenerateNode(env, child)
	end
	return function (env)
		for _, func in ipairs(funcs) do
			if func(env) == bret.SUCCESS then
				return bret.SUCCESS
			end
		end
		return bret.FAIL
	end
end

function NewSequenceNode(env, data)
	local funcs = {}
	for i, child in ipairs(data.children) do
		funcs[i] = GenerateNode(env, child)
	end
	return function (env)
		for _, func in ipairs(funcs) do
			if func(env) == bret.FAIL then
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

function NewCheckNode(env, data)
	local funcs = {}
	for i, child in ipairs(data.children) do
		funcs[i] = GenerateNode(env, child)
	end
	return function (env)
		if not data.args then
			return bret.FAIL
		end
		local code = data.args["value"]
		if not code then
			return bret.FAIL
		end
		return runCode(env, code) and bret.SUCCESS or bret.FAIL
	end
end

local function ret(r)
	return r and bret.SUCCESS or bret.FAIL
end

function NewCmpNode(env, data)
	local funcs = {}
	for i, child in ipairs(data.children) do
		funcs[i] = GenerateNode(env, child)
	end
	return function (env)
		local args = data.args
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

function NewRepeatNode(env, data)
	local childNode = GenerateNode(env, data.children[1])
	return function (env)
		local args = data.args
		local count = args.count
		for i = 1, count do
			if childNode(env) == bret.FAIL then
				return bret.FAIL
			end
		end
		return bret.SUCCESS
	end
end

function NewRepeatUntilSuccessNode(env, data)
	local childNode = GenerateNode(env, data.children[1])
	return function (env)
		local args = data.args
		local maxLoop = args.maxLoop
		for i = 1, maxLoop do
			if childNode(env) == bret.SUCCESS then
				return bret.SUCCESS
			end
			if i < maxLoop then
				CoPool.Yield()
			end
		end
		return bret.FAIL
	end
end

function NewRepeatUntilFailureNode(env, data)
	local childNode = GenerateNode(env, data.children[1])
	return function (env)
		local args = data.args
		local maxLoop = args.maxLoop
		for i = 1, maxLoop do
			if childNode(env) == bret.FAIL then
				return bret.SUCCESS
			end
			if i < maxLoop then
				CoPool.Yield()
			end
		end
		return bret.FAIL
	end
end


function NewWaitNode(env, data)
	return function (env)
		local args = data.args
		local endTime = env.ctx.time + args.time
		if env.ctx.time >= endTime then
			return bret.SUCCESS
		end
		CoPool.Yield()
	end
end

function NewLogNode(env, data)
	return function (env)
		local args = data.args
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

function GenerateNode(env, data)
	local generator = assert(GeneratorMap[data.name], data.name)
	return generator(env, data)
end