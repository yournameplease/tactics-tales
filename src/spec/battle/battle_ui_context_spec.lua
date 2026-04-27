local battle_ui_context = require("src.tactics.battle.battle_ui_context")
local battle_map = require("src.tactics.battle.battle_map")
local point = require("src.tactics.util.point")

local BattleUIContext = battle_ui_context.BattleUIContext

local TW = STATIC_CONFIG.TILE_WIDTH
local TH = STATIC_CONFIG.TILE_HEIGHT
local VW = STATIC_CONFIG.VIEWPORT_WIDTH
local VH = STATIC_CONFIG.VIEWPORT_HEIGHT

local function make_ctx(map_w, map_h)
    local map = battle_map.new(map_w, map_h, {})
    -- minimal stub — only camera methods are under test
    local ctx = setmetatable({
        battle_map = map,
        camera_x = 0,
        camera_y = 0,
    }, BattleUIContext)
    return ctx, map
end

describe("BattleUIContext camera", function()
    describe("initial state", function()
        it("camera_x and camera_y are 0", function()
            local ctx, _ = make_ctx(VW, VH)
            assert.are_equal(0, ctx.camera_x)
            assert.are_equal(0, ctx.camera_y)
        end)
    end)

    describe("clamp_camera", function()
        it("does not move camera when map equals viewport", function()
            local ctx, map = make_ctx(VW, VH)
            ctx.camera_x = 0
            ctx.camera_y = 0
            ctx:clamp_camera(map)
            assert.are_equal(0, ctx.camera_x)
            assert.are_equal(0, ctx.camera_y)
        end)

        it("clamps negative camera to 0", function()
            local ctx, map = make_ctx(VW + 4, VH + 4)
            ctx.camera_x = -10
            ctx.camera_y = -5
            ctx:clamp_camera(map)
            assert.are_equal(0, ctx.camera_x)
            assert.are_equal(0, ctx.camera_y)
        end)

        it("clamps camera past max to max", function()
            local ctx, map = make_ctx(VW + 4, VH + 4)
            local max_x = 4 * TW
            local max_y = 4 * TH
            ctx.camera_x = max_x + 999
            ctx.camera_y = max_y + 999
            ctx:clamp_camera(map)
            assert.are_equal(max_x, ctx.camera_x)
            assert.are_equal(max_y, ctx.camera_y)
        end)
    end)

    describe("move_camera", function()
        it("does not move camera when tile is already within dead zone", function()
            local ctx, map = make_ctx(VW + 8, VH + 8)
            -- place camera so tile 4,4 is well within viewport
            ctx.camera_x = 0
            ctx.camera_y = 0
            ctx:move_camera(map, point.of(4, 4), 2)
            assert.are_equal(0, ctx.camera_x)
            assert.are_equal(0, ctx.camera_y)
        end)

        it("moves camera right when tile exits right dead zone", function()
            local ctx, map = make_ctx(VW + 8, VH + 8)
            ctx.camera_x = 0
            ctx.camera_y = 0
            local dead_zone = 2
            -- tile at x = VW - 1 (last col in viewport): pixel center = (VW-1)*TW + TW//2
            -- threshold = camera_x + (VW - dead_zone)*TW = (VW-2)*TW
            -- pixel > threshold so camera should scroll right
            local tile_x = VW - 1
            ctx:move_camera(map, point.of(tile_x, 0), dead_zone)
            assert.is_true(ctx.camera_x > 0)
        end)

        it("moves camera left when tile exits left dead zone", function()
            local ctx, map = make_ctx(VW + 8, VH + 8)
            ctx.camera_x = 4 * TW  -- scrolled right by 4 tiles
            ctx.camera_y = 0
            local dead_zone = 2
            -- tile at x=0: pixel center = TW//2, camera_x + dead_zone*TW = 4*TW + 2*TW
            -- pixel < threshold so camera should scroll left
            ctx:move_camera(map, point.of(0, 0), dead_zone)
            assert.is_true(ctx.camera_x < 4 * TW)
        end)

        it("clamps camera to 0 when scrolling before map start", function()
            local ctx, map = make_ctx(VW + 4, VH + 4)
            ctx.camera_x = 0
            ctx.camera_y = 0
            ctx:move_camera(map, point.of(0, 0), 3)
            assert.are_equal(0, ctx.camera_x)
            assert.are_equal(0, ctx.camera_y)
        end)

        it("clamps camera to max when tile is at far edge of large map", function()
            local map_extra = 8
            local ctx, map = make_ctx(VW + map_extra, VH + map_extra)
            ctx.camera_x = 0
            ctx.camera_y = 0
            -- move to last tile in map
            ctx:move_camera(map, point.of(VW + map_extra - 1, VH + map_extra - 1), 2)
            local max_x = map_extra * TW
            local max_y = map_extra * TH
            assert.are_equal(max_x, ctx.camera_x)
            assert.are_equal(max_y, ctx.camera_y)
        end)
    end)
end)
