--!strict
local CoreGui = game:GetService("CoreGui")
local PlayerGui = (game:GetService("Players").LocalPlayer :: any).PlayerGui

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local isValidFocusTarget = require(script.Parent.Parent.isValidFocusTarget)

it("returns false for a nil value", function()
	local isValid, reason = isValidFocusTarget(nil)

	expect(isValid).toBe(false)
	expect(reason).toEqual(expect.stringContaining("nil"))
end)

it("returns false for a non-GUI target", function()
	local isValid, reason = isValidFocusTarget(Instance.new("Part"))

	expect(isValid).toBe(false)
	expect(reason).toEqual(expect.stringContaining("Part"))
end)

it("returns false for a value not parented to a LayerCollector", function()
	local isValid, reason = isValidFocusTarget(Instance.new("TextButton"))

	expect(isValid).toBe(false)
	expect(reason).toEqual(expect.stringContaining("LayerCollector like a ScreenGui or SurfaceGui"))
end)

it("returns false for a value not parented to a BasePlayerGui", function()
	local layerCollector = Instance.new("ScreenGui")
	local target = Instance.new("TextButton")
	target.Parent = layerCollector
	local isValid, reason = isValidFocusTarget(target)

	expect(isValid).toBe(false)
	expect(reason).toEqual(expect.stringContaining("BasePlayerGui like PlayerGui or CoreGui"))
end)

describe("valid targets", function()
	local layerCollector
	beforeEach(function()
		layerCollector = Instance.new("ScreenGui")
	end)

	afterEach(function()
		layerCollector.Parent = nil
		layerCollector:Destroy()
	end)

	it("returns true for a valid descendant of CoreGui", function()
		local target = Instance.new("TextButton")
		target.Parent = layerCollector
		layerCollector.Parent = CoreGui

		local isValid, _reason = isValidFocusTarget(target)
		expect(isValid).toBe(true)
	end)

	it("returns true for a valid descendant of PlayerGui", function()
		local target = Instance.new("TextButton")
		target.Parent = layerCollector
		layerCollector.Parent = PlayerGui

		local isValid, _reason = isValidFocusTarget(target)
		expect(isValid).toBe(true)
	end)
end)
