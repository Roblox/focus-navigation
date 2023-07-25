--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local it = JestGlobals.it
local expect = JestGlobals.expect
local jest = JestGlobals.jest

local composeContainerFocusBehaviors = require(script.Parent.Parent.composeContainerFocusBehaviors)

local function targetBehavior(target: GuiObject?)
	return {
		onDescendantFocusChanged = nil,
		getTarget = function()
			return target
		end,
	}
end

local function focusChangedBehavior(fn)
	return {
		onDescendantFocusChanged = fn,
		getTarget = function()
			return nil
		end,
	}
end

it("calls all internal behaviors in sequence", function()
	local focusChanged = jest.fn()
	local behavior1 = focusChangedBehavior(function(value)
		focusChanged(1, value)
	end)
	local behavior2 = focusChangedBehavior(function(value)
		focusChanged(2, value)
	end)
	local behavior3 = focusChangedBehavior(function(value)
		focusChanged(3, value)
	end)
	local composed = composeContainerFocusBehaviors(behavior1, behavior2, behavior3)
	local newFocus: GuiObject = Instance.new("TextButton")

	assert(composed.onDescendantFocusChanged, "Expected onDescendantFocusChanged to be implemented")
	composed.onDescendantFocusChanged(newFocus)

	expect(focusChanged.mock.calls).toEqual({ { 1, newFocus }, { 2, newFocus }, { 3, newFocus } } :: { { any } })

	focusChanged.mockClear()

	local composed2 = composeContainerFocusBehaviors(behavior3, behavior2, behavior1)
	newFocus = Instance.new("ImageButton")
	assert(composed2.onDescendantFocusChanged, "Expected onDescendantFocusChanged to be implemented")
	composed2.onDescendantFocusChanged(newFocus)

	expect(focusChanged.mock.calls).toEqual({ { 3, newFocus }, { 2, newFocus }, { 1, newFocus } } :: { { any } })
end)

it("accepts behaviors with nil onDescendantFocusChanged values", function()
	local target1, target2 = Instance.new("TextButton"), Instance.new("ImageButton")
	local behavior1, behavior2 = targetBehavior(target1), targetBehavior(target2)

	local composed = composeContainerFocusBehaviors(behavior1, behavior2)
	local newFocus: GuiObject = Instance.new("TextButton")

	expect(composed.onDescendantFocusChanged).toBeDefined()
	expect(function()
		assert(composed.onDescendantFocusChanged, "expected onDescendantFocused to be defined")
		composed.onDescendantFocusChanged(newFocus)
	end).never.toThrow()
end)

it("returns the first valid target starting from the beginning of the list", function()
	local target1, target2 = Instance.new("TextButton"), Instance.new("ImageButton")
	local behavior1, behavior2 = targetBehavior(target1), targetBehavior(target2)

	local compose1then2 = composeContainerFocusBehaviors(behavior1, behavior2)
	expect(compose1then2.getTarget()).toBe(target1)

	local compose2then1 = composeContainerFocusBehaviors(behavior2, behavior1)
	expect(compose2then1.getTarget()).toBe(target2)
end)
