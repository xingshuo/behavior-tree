local BNode = require("behavior_node")
local Const = require("const")
local bret = Const.bret

--[[
Doc:
	+ 只能有一个子节点，多个仅执行第一个
	+ 只有当子节点返回失败时，才返回成功，其它情况返回运行中状态
	+ 如果设定了尝试次数，超过指定次数则返回失败

Original Code:
	run = function(node, env, max_loop)
		local max_loop = node.args.maxLoop

		local count, resume_ret = node:resume(env)
		if count then
			if resume_ret == bret.FAIL then
				return bret.SUCCESS
			elseif count >= max_loop then
				return bret.FAIL
			else
				count = count + 1
			end
		else
			count = 1
		end

		local r = node.children[1]:run(env)
		if r == bret.FAIL then
			return bret.SUCCESS
		else
			return node:yield(env, count)
		end
	end
]]

return function (env, nodeData)
	local child = BNode.GenerateNode(env, nodeData.children[1])
	return function ()
		if child() == bret.FAIL then
			return bret.SUCCESS
		end
		local maxLoop = nodeData.args.maxLoop
		while maxLoop > 1 do
			if env.tree:Yield() then
				return bret.ABORT
			end
			if child() == bret.FAIL then
				return bret.SUCCESS
			end
			maxLoop = maxLoop - 1
		end
		return bret.FAIL
	end
end