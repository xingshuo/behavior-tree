local Const = require("const")
local bret = Const.bret

--[[
Doc:
	等待特定次数

Original Code:
	run = function(node, env)
		local args = node.args
		local t = node:resume(env)
		if t then
			t = t - 1
			if t <= 0 then
				print('DONE')
				return bret.SUCCESS
			else
				print('CONTINUE', "node#" .. node.data.id .. "Last tick", t)
				node:yield(env, t)
				return bret.RUNNING
			end
		end
		print('WaitForCount', args.tick)
		return node:yield(env, args.tick)
	end
]]

return function (env, nodeData)
	return function ()
		local tick = nodeData.args.tick
		print('WaitForCount', tick)
		for i = tick, 1, -1 do
			if env.tree:Yield() then
				return bret.ABORT
			end
			print('CONTINUE', "node#" .. nodeData.id .. "Last tick", i)
		end
		return bret.SUCCESS
	end
end