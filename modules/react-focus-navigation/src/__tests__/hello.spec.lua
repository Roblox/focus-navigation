local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local it = JestGlobals.it
local expect = JestGlobals.expect

local hello = require(script.Parent.Parent.hello)

it("should issue a greeting", function()
	local greeting = hello()

	expect(greeting).toContain("Hello")
	expect(greeting).toContain("Focus Navigation")
end)

return {}
