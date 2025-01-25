local BTree = require("behavior_tree")
local Json = require "json"

local function load_tree(path)
    local file, err = io.open(path, 'r')
    assert(file, err)
    local str = file:read('*a')
    file:close()
    return Json.decode(str)
end

local function test_repeat_until_success()
	print("=================== test repeat until success ========================")
	local treeData = load_tree("trees/test-repeat-until-success.json")
	local ctx = {time = 1}
	local btree = BTree.NewTree(treeData, ctx)
	for i = 1, 7 do
		ctx.time = ctx.time + 1
		btree:Run()
	end
end

test_repeat_until_success()

local function test_repeat_until_fail()
	print("=================== test repeat until fail ========================")
	local treeData = load_tree("trees/test-repeat-until-failure.json")
	local ctx = {time = 1}
	local btree = BTree.NewTree(treeData, {
		ctx   = ctx,
	})
	for i = 1, 7 do
		ctx.time = ctx.time + 1
		btree:Run()
	end
end

test_repeat_until_fail()

local function test_parallel()
	print("=================== test parallel ========================")
	local treeData = load_tree("trees/test-parallel.json")
	local ctx = {time = 1}
	local btree = BTree.NewTree(treeData, ctx)
	for i = 1, 14 do
		ctx.time = ctx.time + 1
		btree:Run()
	end
end

test_parallel()

local function test_parallel_with_wait()
	print("=================== test parallel with wait ========================")
	local treeData = load_tree("trees/test-parallel-with-wait.json")
	local ctx = {}
	local btree = BTree.NewTree(treeData, ctx)
	for i = 1, 8 do
		btree:Run()
	end
end

test_parallel_with_wait()

local function test_abort()
	print("=================== test abort========================")
	local treeData = load_tree("trees/test-parallel-with-wait.json")
	local ctx = {}
	local btree = BTree.NewTree(treeData, ctx)
	for i = 1, 8 do
		btree:Run()
		if i == 3 then
			btree:Interrupt()
		end
	end
end

test_abort()

local function test_catch_exception()
	print("=================== test catch exception========================")
	local treeData = load_tree("trees/test-parallel.json")
	local ctx = {}
	local btree = BTree.NewTree(treeData, ctx)
	for i = 1, 14 do
		local ok, err = xpcall(btree.Run, debug.traceback, btree)
		if not ok then
			print("catch exception:", err)
			break
		end
	end

	ctx.time = 0
	for i = 1, 14 do
		ctx.time = ctx.time + 1
		btree:Run()
	end
end

test_catch_exception()