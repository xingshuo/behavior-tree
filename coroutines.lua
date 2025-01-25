local coroutine = coroutine
local table = table
local traceback = debug.traceback
local tostring = tostring
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
		local tb = traceback(co,tostring(msg))
		if coroutine.close then -- above lua 5.4
			coroutine.close(co)
		end
		error(tb)
	end
	return table.unpack(rets, 2)
end

-- TODO: trace log
function M.Yield(...)
    return coroutine.yield(...)
end

return M