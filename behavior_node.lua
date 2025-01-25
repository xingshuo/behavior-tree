local Const = require("const")

local bret = Const.bret

local process = nil

local M = {}

function M.Process(custom)
	process = custom
end

function M.GenerateNode(env, nodeData)
	if not process then
		process = require("sample_process")
	end
	local builder = assert(process[nodeData.name], nodeData.name)
	local run = builder(env, nodeData)
	return function ()
		if env.abort then
			return bret.ABORT
		end
		local ret = run()
		if env.abort then
			return bret.ABORT
		end
		if ret == bret.ABORT then
			env.abort = true
			return bret.ABORT
		end
		return ret
	end
end

return M