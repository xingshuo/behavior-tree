﻿local BNode = require("behavior_node")
local Const = require("const")
local bret = Const.bret

--[[
Doc:
	+ 拥有三个子节点(至少两个)
	+ 当第一个子节点返回SUCCESS的时候执行第二个子节点并返回此子节点的返回值
	+ 否则执行第三个子节点并返回这个节点的返回值,若无第三个子节点,则返回FAIL

Original Code:
	local function child_ret(node, env, idx)
		local r = node.children[idx]:Run(env)
		return r == bret.RUNNING and node:yield(env, idx) or r
	end

	local function ifelse(node, env, ret)
		if ret == bret.RUNNING then
			return ret
		end
		if ret == bret.SUCCESS then
			return child_ret(node, env, 2)
		elseif node.children[3] then
			return child_ret(node, env, 3)
		else
			return bret.FAIL
		end
	end

	run = function(node, env)
		assert(#node.children >= 2, "at least two children")

		local last_idx, last_ret = node:resume(env)
		if last_ret == bret.RUNNING then
			return last_ret
		end
		if last_idx == 1 then
			return ifelse(node, env, last_ret)
		elseif last_idx == 2 or last_idx == 3 then
			return last_ret
		end

		local r = node.children[1]:Run(env)
		if r == bret.RUNNING then
			return node:yield(env, 1)
		end
		return ifelse(node, env, r)
	end
]]

return function (env, nodeData)
	assert(#nodeData.children >= 2, "at least two children")
	local children = {}
	for i, childData in ipairs(nodeData.children) do
		children[i] = BNode.GenerateNode(env, childData)
	end
	return function ()
		if children[1]() == bret.SUCCESS then
			return children[2]()
		end
		local child = children[3]
		if not child then
			return bret.FAIL
		end
		return child()
	end
end