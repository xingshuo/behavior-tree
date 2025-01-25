local BTree = require("behavior_tree")
local Json = require "json"

local function load_tree(path)
    local file, err = io.open(path, 'r')
    assert(file, err)
    local str = file:read('*a')
    file:close()
    return Json.decode(str)
end

local function test_parallel()
	local treeData = load_tree("trees/test-parallel.json")
	local ctx = {time = 1}
	local btree = BTree.NewTree(treeData, ctx)
	for i = 1, 6 do
		ctx.time = ctx.time + 1
		btree:run()
	end
	print("=================== test parallel ========================")
end

test_parallel()