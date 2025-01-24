local BNode = require("behavior_node")
local Const = require("const")
local bret = Const.bret

--[[
Doc:
	+ 只能有一个子节点，多个仅执行第一个
	+ 当子节点返回「失败」时，退出遍历并返回「失败」状态
	+ 其它情况返回成功/正在运行

Original Code:
	run = function(node, env)
		local count = node.args.count
		local last_i, resume_ret = node:resume(env)
		if last_i then
			if resume_ret == bret.RUNNING then
				error(string.format("%s->${%s}#${$d}: unexpected status error",
					node.tree.name, node.name, node.id))
			elseif resume_ret == bret.FAIL then
				return bret.FAIL
			end
			last_i = last_i + 1
		else
			last_i = 1
		end

		for i = last_i, count do
			local r = node.children[1]:run(env)
			if r == bret.RUNNING then
				return node:yield(env, i)
			elseif r == bret.FAIL then
				return bret.FAIL
			end
		end
		return bret.SUCCESS
	end
]]

return function (env, nodeData)
	local child = BNode.GenerateNode(env, nodeData.children[1])
	return function ()
		local count = nodeData.args.count
		for i = 1, count do
			if child() == bret.FAIL then
				return bret.FAIL
			end
		end
		return bret.SUCCESS
	end
end