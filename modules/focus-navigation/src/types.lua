--!strict
export type InputEvent = {
	KeyCode: Enum.KeyCode,
	UserInputState: Enum.UserInputState,
	UserInputType: Enum.UserInputType,
	Position: Vector3?,
	Delta: Vector3?,
}

-- TODO: Union with whatever data we end up using for focus/blur events
export type EventData = InputEvent | nil
export type InputDevice = "Gamepad" | "Keyboard" | "Remote"
export type EventMap = {
	[Enum.KeyCode]: string,
}

return {}
