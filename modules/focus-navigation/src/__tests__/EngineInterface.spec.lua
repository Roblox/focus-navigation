--!strict
local GuiService = game:GetService("GuiService")

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local EventPropagation = require(Packages.EventPropagation)

local it = JestGlobals.it
local expect = JestGlobals.expect
local afterEach = JestGlobals.afterEach

local createGuiObjectTree = require(script.Parent.createGuiObjectTree)

local FocusNavigationService = require(script.Parent.Parent.FocusNavigationService)
local EngineInterface = require(script.Parent.Parent.EngineInterface)

type EventPhase = EventPropagation.EventPhase
type EventHandler = FocusNavigationService.EventHandler

local CoreGui = game:GetService("CoreGui")
local PlayerGui = (game:GetService("Players").LocalPlayer :: any).PlayerGui

local function getMountedGui(mountTarget)
	return createGuiObjectTree({
		root = { "ScreenGui", mountTarget },
		container = { "Frame", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
		button = { "ImageButton", "container", { SelectionOrder = 1, Size = UDim2.fromScale(0.5, 0.5) } },
	})
end

local mountedTree, service
afterEach(function()
	if mountedTree then
		mountedTree.root:Destroy()
		mountedTree = nil :: any
	end
	if service then
		service:teardown()
		service = nil :: any
	end
	GuiService.SelectedObject = nil
	GuiService.SelectedCoreObject = nil
end)

it("should be able to focus the correct input property under CoreGui", function()
	mountedTree = getMountedGui(CoreGui)
	service = FocusNavigationService.new(EngineInterface.CoreGui)
	service:focusGuiObject(mountedTree.button, false)
	expect(GuiService.SelectedCoreObject).toEqual(mountedTree.button)
	expect(GuiService.SelectedObject).toBeNil()
end)

it("should be able to focus the correct input property under PlayerGui", function()
	mountedTree = getMountedGui(PlayerGui)
	service = FocusNavigationService.new(EngineInterface.PlayerGui)
	service:focusGuiObject(mountedTree.button, false)
	expect(GuiService.SelectedObject).toEqual(mountedTree.button)
	expect(GuiService.SelectedCoreObject).toBeNil()
end)

it("should be able to focus child of non-Selectable CoreGui descendant", function()
	mountedTree = getMountedGui(CoreGui)
	service = FocusNavigationService.new(EngineInterface.CoreGui)
	service:focusGuiObject(mountedTree.container, false)
	expect(GuiService.SelectedCoreObject).toEqual(mountedTree.button)
	expect(GuiService.SelectedObject).toBeNil()
end)

it("should be able to focus child of non-Selectable Player descendant", function()
	mountedTree = getMountedGui(PlayerGui)
	service = FocusNavigationService.new(EngineInterface.CoreGui)
	service:focusGuiObject(mountedTree.container, false)
	expect(GuiService.SelectedObject).toEqual(mountedTree.button)
	expect(GuiService.SelectedCoreObject).toBeNil()
end)
