local coroutine = coroutine
local table = table

local coroutine_pool = setmetatable({}, { __mode = "kv" })

local M = {}

function M.Create(f)
    local co = table.remove(coroutine_pool)
	if co == nil then
		co = coroutine.create(function(...)
			local rets = {f(...)}
			while true do
				f = nil
				coroutine_pool[#coroutine_pool+1] = co
				local nret = #rets
				if nret == 0 then
					f = coroutine.yield()
				else
					f = coroutine.yield(table.unpack(rets, 1, nret))
				end
				rets = {f(coroutine.yield())}
			end
		end)
	else
		coroutine.resume(co, f)
	end
	return co
end

function M.Resume(co, ...)
	local rets = {coroutine.resume(co, ...)}
	local ok = rets[1]
	if not ok then
		local msg = rets[2]
		error(msg, 2)
	end
	return table.unpack(rets, 2)
end

function M.Yield(...)
    return coroutine.yield(...)
end

return M