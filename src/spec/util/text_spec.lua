local luassert = require("luassert")
local spy = require("luassert.spy")

local text = require("src.tactics.util.text")

-- note: these were llm generated
-- they look servicable, but do replace with more accurate once you attempt to update the text renderer

describe("tactics.util.text", function()
    local old_print
    local print_spy

    before_each(function()
        old_print = _G.print
        print_spy = spy.new(function(str, x, y, _color)
            return x + #str * 4, y + 8
        end)
        _G.print = print_spy
    end)

    after_each(function()
        _G.print = old_print
    end)

    describe("wrapping", function()
        it("should not wrap text shorter than the width", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"hello world"}, props, 100, 20)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are_same({{"hello world"}}, lines)
        end)

        it("should wrap a single long line of text", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"this is a long line"}, props, 40, 40)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are_same({{"this is a", "long line"}}, lines)
        end)

        it("should handle multiple paragraphs with wrapping", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"first long line", "second long line"}, props, 40, 60)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are_same({{"first long", "line"}, {"second", "long line"}}, lines)
        end)

        it("should truncate text with ellipsis when wrap mode is 'ellipsis'", function()
            local props = { justify = "left", direction = "down", wrap = "ellipsis" }
            local t = text.new({"a very long line that should be truncated"}, props, 40, 20)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are_same({{"a very l..."},}, lines)
        end)

        it("should not wrap text when wrap mode is 'no_wrap'", function()
            local props = { justify = "left", direction = "down", wrap = "no_wrap" }
            local long_text = "this is a very long line that should not wrap"
            local t = text.new({long_text}, props, 40, 20)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are_same({{long_text}}, lines)
        end)
    end)

    describe("get_wrapped_rows", function()
        it("should return the total number of rows after wrapping", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"one line", "two lines wrap", "three lines will wrap"}, props, 30, 100)
            luassert.are_equal(9, t:get_wrapped_rows())
        end)
    end)
end)
