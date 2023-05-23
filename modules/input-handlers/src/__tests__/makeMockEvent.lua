local function makeMockEvent(
	inputState: Enum.UserInputState,
	keyCode: Enum.KeyCode?,
	inputType: Enum.UserInputType?,
	delta: Vector3?,
	position: Vector3?
)
	return {
		UserInputState = inputState,
		KeyCode = keyCode or Enum.KeyCode.ButtonA,
		UserInputType = inputType or Enum.UserInputType.Gamepad1,
		Delta = delta,
		Position = position,
	}
end

return makeMockEvent
