local Const = require("const")
local bret = Const.bret

--[[
Doc:
	等待时长/tick次数

Original Code:
	run = function(node, env)
		local args = node.args
		local t = node:resume(env)
		if t then
			if env.ctx.time >= t then
				print('CONTINUE')
				return bret.SUCCESS
			else
				print('WAITING', "node#" .. node.data.id)
				return bret.RUNNING
			end
		end
		print('Wait', args.time)
		return node:yield(env, env.ctx.time + args.time)
	end
]]

return function (env, nodeData)
	return function ()
		local endTime = env.ctx.time + nodeData.args.time
		while env.ctx.time < endTime do
			if env.tree:Yield() then
				return bret.ABORT
			end
		end
		return bret.SUCCESS
	end
end