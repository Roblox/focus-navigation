--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect
local jest = JestGlobals.jest
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local useComposedRef = require(script.Parent.Parent.useComposedRef)

local callbackRef, callbackRefFn
beforeEach(function()
	callbackRef, callbackRefFn = jest.fn()
end)

afterEach(function()
	cleanup()
end)

local function SimpleButton(props)
	local ref = useComposedRef(callbackRefFn, props.inputRef)
	return React.createElement("TextButton", {
		Text = props.text,
		ref = ref,
	})
end

it("should supply a valid ref when no inner ref is provided", function()
	local capturedRef, refSpy
	local function Button(props)
		capturedRef = useComposedRef(callbackRefFn)
		local spy, spyFn = jest.fn(capturedRef)
		refSpy = spy
		return React.createElement("TextButton", {
			Text = props.text,
			ref = spyFn,
		})
	end
	local result = render(React.createElement(Button, {
		text = "foo",
	}))

	local instance = result.getByText("foo")
	expect(instance).toBeDefined()
	expect(capturedRef).toEqual(expect.any("function"))
	expect(refSpy).toHaveBeenCalledWith(instance)
	expect(callbackRef).toHaveBeenCalledTimes(1)
	expect(callbackRef).toHaveBeenCalledWith(instance)
end)

it("should accept and wrap a function ref", function()
	local refSpy, refSpyFn = jest.fn()
	local result = render(React.createElement(SimpleButton, {
		inputRef = refSpyFn,
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	expect(instance).toBeDefined()
	expect(refSpy).toHaveBeenCalledWith(instance)
	expect(callbackRef).toHaveBeenCalledTimes(1)
	expect(callbackRef).toHaveBeenCalledWith(instance)

	local newRefSpy, newRefSpyFn = jest.fn()
	result.rerender(React.createElement(SimpleButton, {
		inputRef = newRefSpyFn,
		text = "Show More",
	}))

	instance = result.getByText("Show More")
	expect(refSpy).toHaveBeenLastCalledWith(nil)
	expect(newRefSpy).toHaveBeenCalledWith(instance)
	-- The callback is getting called when the ref gets nilled out as well
	expect(callbackRef).toHaveBeenCalledWith(nil)
	expect(callbackRef).toHaveBeenCalledTimes(3)
	expect(callbackRef).toHaveBeenLastCalledWith(instance)
end)

it("should accept and wrap an object ref", function()
	local inputRef = React.createRef()
	local result = render(React.createElement(SimpleButton, {
		inputRef = inputRef,
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	expect(instance).toBeDefined()
	expect(inputRef.current).toEqual(result.getByText("Show More"))
	expect(callbackRef).toHaveBeenCalledTimes(1)
	expect(callbackRef).toHaveBeenCalledWith(instance)

	local newInputRef = React.createRef()
	result.rerender(React.createElement(SimpleButton, {
		inputRef = newInputRef,
		text = "Show More",
	}))

	instance = result.getByText("Show More")
	expect(inputRef.current).toEqual(nil)
	expect(newInputRef.current).toEqual(instance)
	-- The callback is getting called when the ref gets nilled out as well
	expect(callbackRef).toHaveBeenCalledWith(nil)
	expect(callbackRef).toHaveBeenCalledTimes(3)
	expect(callbackRef).toHaveBeenLastCalledWith(instance)
end)
