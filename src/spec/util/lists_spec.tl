local type _ = require("busted")
local luassert <const> = require("luassert")

local lists <const> = require("src.tactics.util.lists")

describe("util lists api", function()
	it("reverse should reverse input", function()
		local list = {1, 2, 3}
		luassert.are_same({3, 2, 1}, lists.do_reverse(list))
	end)
end)
