local BNode = require("behavior_node")
local Const = require("const")
local bret = Const.bret

--[[
Doc:
	+ 一直往下执行，有子节点返回成功则返回成功，若全部节点返回失败则返回失败
	+ 子节点是或 (OR) 的关系

Original Code:
	run = function(node, env)
		local last_idx, last_ret = node:resume(env)
		if last_idx then
			if last_ret == bret.SUCCESS then
				return last_ret
			elseif last_ret == bret.FAIL then
				last_idx = last_idx + 1
			else
				error(string.format("%s->${%s}#${$d}: unexpected status error",
					node.tree.name, node.name, node.id))
			end
		else
			last_idx = 1
		end

		for i = last_idx, #node.children do
			local child = node.children[i]
			local r = child:run(env)
			if r == bret.RUNNING then
				return node:yield(env, i)
			end
			if r == bret.SUCCESS then
				return r
			end
		end
		return bret.FAIL
	end
]]

return function (env, nodeData)
	local children = {}
	for i, childData in ipairs(nodeData.children) do
		children[i] = BNode.GenerateNode(env, childData)
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