local Process = require("sample_process")
local Const = require("const")

local bret = Const.bret

local M = {}

function M.Process(custom)
	Process = custom
end

function M.GenerateNode(env, nodeData)
	local builder = assert(Process[nodeData.name], nodeData.name)
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