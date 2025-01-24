return {
	-- 复合节点
	IfElse             = require "nodes.composites.ifelse",
	Parallel           = require "nodes.composites.parallel",
	Selector           = require "nodes.composites.selector",
	Sequence           = require "nodes.composites.sequence",

	-- 装饰节点
	Once               = require "nodes.decorators.once",
	Invert             = require "nodes.decorators.invert",
	AlwaysFail         = require "nodes.decorators.always_fail",
	AlwaysSuccess      = require "nodes.decorators.always_success",
	RepeatUntilSuccess = require "nodes.decorators.repeat_until_success",
	RepeatUntilFailure = require "nodes.decorators.repeat_until_fail",
	Repeat             = require "nodes.decorators.repeat",

	-- 条件节点

	-- 行为节点
	Log                = require "behavior3.nodes.actions.log",
	Wait               = require "behavior3.nodes.actions.wait",
	WaitForCount       = require "behavior3.nodes.actions.wait_for_count",
}