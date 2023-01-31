--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect
local jest = JestGlobals.jest
local afterEach = JestGlobals.afterEach

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local useEventLifecycleRef = require(script.Parent.Parent.useEventLifecycleRef)

afterEach(function()
	cleanup()
end)

local function SimpleButton(props)
	local ref = useEventLifecycleRef(props.bind, props.unbind)
	return React.createElement("TextButton", {
		Text = props.text,
		ref = ref,
	})
end

it("should call the bind function when the ref is assigned", function()
	local bind = jest.fn()
	local result = render(React.createElement(SimpleButton, {
		text = "foo",
		bind = bind,
	}))

	local instance = result.getByText("foo")
	expect(bind).toHaveBeenCalledTimes(1)
	expect(bind).toHaveBeenCalledWith(instance)
end)

it("should call the unbind function when the ref is assigned", function()
	local unbind = jest.fn()
	local result = render(React.createElement(SimpleButton, {
		text = "foo",
		bind = function() end,
		unbind = unbind,
	}))

	expect(unbind).toHaveBeenCalledTimes(0)

	local instance = result.getByText("foo")
	result.unmount()

	expect(unbind).toHaveBeenCalledTimes(1)
	expect(unbind).toHaveBeenCalledWith(instance)
end)

it("should unbind the old and bind the new values when the ref changes", function()
	local bind = jest.fn()
	local unbind = jest.fn()
	local result = render(React.createElement(SimpleButton, {
		text = "foo",
		bind = bind,
		unbind = unbind,
	}))

	local oldInstance = result.getByText("foo")
	expect(bind).toHaveBeenCalledTimes(1)
	expect(bind).toHaveBeenCalledWith(oldInstance)
	expect(unbind).toHaveBeenCalledTimes(0)

	local function SimpleLabel(props)
		local ref = useEventLifecycleRef(props.bind, props.unbind)
		return React.createElement("TextLabel", {
			Text = props.text,
			ref = ref,
		})
	end
	result.rerender(React.createElement(SimpleLabel, {
		text = "bar",
		bind = bind,
		unbind = unbind,
	}))

	local newInstance = result.getByText("bar")
	expect(unbind).toHaveBeenCalledTimes(1)
	expect(unbind).toHaveBeenCalledWith(oldInstance)
	expect(bind).toHaveBeenCalledTimes(2)
	expect(bind).toHaveBeenLastCalledWith(newInstance)
end)
