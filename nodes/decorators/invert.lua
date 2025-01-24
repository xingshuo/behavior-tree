local BNode = require("behavior_node")
local Const = require("const")
local bret = Const.bret

--[[
Doc:
	+ 将子节点的返回值取反
	+ 只能有一个子节点，多个仅执行第一个

Original Code:
	run = function(node, env)
		local r
		if node:resume(env) then
			r = env.last_ret
		else
			r = node.children[1]:run(env)
		end

		if r == bret.SUCCESS then
			return bret.FAIL
		elseif r == bret.FAIL then
			return bret.SUCCESS
		else
			return node:yield(env)
		end
	end
]]

return function (env, nodeData)
	local child = BNode.GenerateNode(env, nodeData.children[1])
	return function ()
		local r = child()
		return r == bret.SUCCESS and bret.FAIL or bret.SUCCESS
	end
end