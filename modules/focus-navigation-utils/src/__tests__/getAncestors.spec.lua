--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect

local getAncestors = require(script.Parent.Parent.getAncestors)

it("should return a single value for an unparented instance", function()
	local Foo = Instance.new("Folder")
	expect(getAncestors(Foo)).toEqual({ Foo })
end)

it("should return ancestors for an unparented tree", function()
	local Foo = Instance.new("Folder")
	local Bar = Instance.new("Folder")
	local Baz = Instance.new("Folder")
	Foo.Parent = Bar
	Bar.Parent = Baz

	expect(getAncestors(Foo)).toEqual({ Foo, Bar, Baz })
end)

it("should not contain any siblings or descendants", function()
	local Foo = Instance.new("Folder")
	local Bar = Instance.new("Folder")
	local Baz = Instance.new("Folder")
	Foo.Parent = Bar
	Bar.Parent = Baz

	local Sibling = Instance.new("Folder")
	Sibling.Parent = Bar
	local Child = Instance.new("Folder")
	Child.Parent = Foo

	expect(getAncestors(Foo)).never.toContain(Sibling)
	expect(getAncestors(Foo)).never.toContain(Child)
end)

it("should return all ancestors for a parented tree", function()
	local Foo = Instance.new("Folder")
	local Bar = Instance.new("Folder")
	Foo.Parent = Bar

	local Players = game:GetService("Players")
	local LocalPlayer: any = Players.LocalPlayer
	Bar.Parent = LocalPlayer.PlayerGui

	expect(getAncestors(Foo)).toEqual({ Foo, Bar, LocalPlayer.PlayerGui, LocalPlayer, Players, game } :: { any })
end)
