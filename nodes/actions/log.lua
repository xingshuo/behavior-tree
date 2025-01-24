local Const = require("const")
local bret = Const.bret

--[[
Doc:
	打印日志

Original Code:
	run = function(node, env)
		print(node.args.message)
		return bret.SUCCESS
	end
]]

return function (env, nodeData)
	return function ()
		print(nodeData.args.message)
		return bret.SUCCESS
	end
end