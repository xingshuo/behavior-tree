﻿local BNode = require("behavior_node")
local Const = require("const")
local bret = Const.bret

--[[
Doc:
	+ 只能有一个子节点,多个仅执行第一个
	+ 不管子节点是否成功都返回失败

Original Code:
	run = function(node, env)
		local yeild, last_ret = node:resume(env)
		if yeild then
			if last_ret == bret.RUNNING then
				error(string.format("%s->${%s}#${$d}: unexpected status error",
					node.tree.name, node.name, node.id))
			end
			return bret.FAIL
		end

		local child = node.children[1]
		if not child then
			return bret.FAIL
		end
		local r = child:run(env)
		if r == bret.RUNNING then
			return node:yield(env)
		end
		return bret.FAIL
	end
]]

return function (env, nodeData)
	local childData = nodeData.children[1]
	local child = childData and BNode.GenerateNode(env, childData)
	return function ()
		if child then
			child()
		end
		return bret.FAIL
	end
end