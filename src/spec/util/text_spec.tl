local type _ = require("busted")
local luassert: any = require("luassert")
local spy: any = require("luassert.spy")

local text = require("src.tactics.util.text")

describe("tactics.util.text", function()
    local old_print: any = nil
    local print_spy: any = nil

    before_each(function()
        old_print = pt.print
        print_spy = spy.new(function(str: string, _x: number, _y: number, _color: number): number
            return #str * 4
        end)
        pt.print = (print_spy as {call: any}).call
    end)

    after_each(function()
        pt.print = old_print as function
    end)

    describe("wrapping", function()
        it("should not wrap text shorter than the width", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"hello world"}, props, 100, 20)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are.same({{"hello world"}}, lines)
        end)

        it("should wrap a single long line of text", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"this is a long line"}, props, 40, 40)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are.same({{"this is a", "long line"}}, lines)
        end)

        it("should handle multiple paragraphs with wrapping", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"first long line", "second long line"}, props, 40, 60)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are.same({{"first long", "line"}, {"second", "long line"}}, lines)
        end)

        it("should truncate text with ellipsis when wrap mode is 'ellipsis'", function()
            local props = { justify = "left", direction = "down", wrap = "ellipsis" }
            local t = text.new({"a very long line that should be truncated"}, props, 40, 20)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are.same({{"a very..."},}, lines)
        end)

        it("should not wrap text when wrap mode is 'no_wrap'", function()
            local props = { justify = "left", direction = "down", wrap = "no_wrap" }
            local long_text = "this is a very long line that should not wrap"
            local t = text.new({long_text}, props, 40, 20)
            t:calculate_wrapping()
            local lines = t:get_lines()
            luassert.are.same({{long_text}}, lines)
        end)
    end)

    describe("get_wrapped_rows", function()
        it("should return the total number of rows after wrapping", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"one line", "two lines wrap", "three lines will wrap"}, props, 30, 100)
            luassert.are.equal(7, t:get_wrapped_rows())
        end)
    end)

    describe("draw", function()
        it("should call pt.print with correct coordinates and text for each wrapped line", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"wrap this"}, props, 20, 40)
            t:draw(10, 20, 7, nil)
            
            (luassert.spy(print_spy) as any).was_called(2)
            (luassert.spy(print_spy) as any).was_called_with("wrap", 10, 20, 7)
            (luassert.spy(print_spy) as any).was_called_with("this", 10, 20 + 10, 7)
        end)
        
        it("should respect justification when drawing", function()
            local props = { justify = "center", direction = "down", wrap = "no_wrap" }
            local t = text.new({"center"}, props, 100, 20)
            t:draw(0, 0, 7, nil)
            
            local expected_x = (100 - (#"center" * 4)) // 2
            (luassert.spy(print_spy) as any).was_called_with("center", expected_x, 0, 7)
        end)
        
        it("should respect alignment when drawing", function()
            local props = { justify = "left", direction = "down", wrap = "no_wrap", align = true }
            local t = text.new({"left|right"}, props, 100, 20)
            t:draw(0, 0, 7, nil)
            
            (luassert.spy(print_spy) as any).was_called_with("left", 0, 0, 7)
            local expected_x = 100 - (#"right" * 4) - 1
            (luassert.spy(print_spy) as any).was_called_with("right", expected_x, 0, 7)
        end)

        it("should only draw up to the specified number of characters", function()
            local props = { justify = "left", direction = "down", wrap = "wrap" }
            local t = text.new({"hello world"}, props, 100, 40)
            t:draw(10, 20, 7, {7})

            (luassert.spy(print_spy) as any).was_called(1)
            (luassert.spy(print_spy) as any).was_called_with("hello w", 10, 20, 7)
        end)
    end)
end)