--!strict
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local types = require(script.Parent.types)
type EngineInterface = types.EngineInterface

local CoreInterface: EngineInterface = {
	getSelection = function()
		return GuiService.SelectedCoreObject
	end,
	setSelection = function(guiObject)
		GuiService.SelectedCoreObject = guiObject
	end,
	SelectionChanged = GuiService:GetPropertyChangedSignal("SelectedCoreObject"),
	InputBegan = UserInputService.InputBegan,
	InputChanged = UserInputService.InputChanged,
	InputEnded = UserInputService.InputEnded,
	LastInputTypeChanged = UserInputService.LastInputTypeChanged,
}

local PlayerGuiInterface: EngineInterface = {
	getSelection = function()
		return GuiService.SelectedObject
	end,
	setSelection = function(guiObject)
		GuiService.SelectedObject = guiObject
	end,
	SelectionChanged = GuiService:GetPropertyChangedSignal("SelectedObject"),
	InputBegan = UserInputService.InputBegan,
	InputChanged = UserInputService.InputChanged,
	InputEnded = UserInputService.InputEnded,
	LastInputTypeChanged = UserInputService.LastInputTypeChanged,
}

return {
	CoreGui = CoreInterface,
	PlayerGui = PlayerGuiInterface,
}
