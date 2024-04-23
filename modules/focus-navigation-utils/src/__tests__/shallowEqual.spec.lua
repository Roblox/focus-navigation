--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect

local shallowEqual = require(script.Parent.Parent.shallowEqual)

local a = {
	a = "a",
	b = { x = 1 },
	c = 6,
}

local b = {
	a = a.a,
	b = a.b,
	c = a.c,
}

local c = {
	a = a.a,
	b = { x = 1 },
	c = a.c,
}

local d = {
	a = a.a,
	b = a.b,
	c = a.c,
	d = "hello",
}

it("should compare dictionaries with the same keys", function()
	expect(shallowEqual(a, a)).toBe(true)
	expect(shallowEqual(a, b)).toBe(true)
end)

it("should only compare shallowly", function()
	expect(shallowEqual(a, c)).toBe(false)
	expect(shallowEqual(b, c)).toBe(false)
end)

it("should return false when tables have different keys", function()
	expect(shallowEqual(a, d)).toBe(false)
	expect(shallowEqual(b, d)).toBe(false)
end)
