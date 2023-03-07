local UserInputService = game:GetService("UserInputService")

local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)

type LastInputDevice = "Keyboard" | "Mouse" | "Gamepad" | "None"

local INPUT_TYPE_TO_DEVICE: { [Enum.UserInputType]: LastInputDevice } = {
	[Enum.UserInputType.MouseButton1] = "Mouse",
	[Enum.UserInputType.MouseButton2] = "Mouse",
	[Enum.UserInputType.MouseButton3] = "Mouse",
	[Enum.UserInputType.MouseWheel] = "Mouse",
	[Enum.UserInputType.MouseMovement] = "Mouse",
	[Enum.UserInputType.Touch] = "None",
	[Enum.UserInputType.Keyboard] = "Keyboard",
	[Enum.UserInputType.Focus] = "None",
	[Enum.UserInputType.Accelerometer] = "None",
	[Enum.UserInputType.Gyro] = "None",
	[Enum.UserInputType.Gamepad1] = "Gamepad",
	[Enum.UserInputType.Gamepad2] = "Gamepad",
	[Enum.UserInputType.Gamepad3] = "Gamepad",
	[Enum.UserInputType.Gamepad4] = "Gamepad",
	[Enum.UserInputType.Gamepad5] = "Gamepad",
	[Enum.UserInputType.Gamepad6] = "Gamepad",
	[Enum.UserInputType.Gamepad7] = "Gamepad",
	[Enum.UserInputType.Gamepad8] = "Gamepad",
	[Enum.UserInputType.TextInput] = "Keyboard",
	[Enum.UserInputType.InputMethod] = "None",
	[Enum.UserInputType.None] = "None",
}

local function useLastInputDevice()
	local initialValue = INPUT_TYPE_TO_DEVICE[UserInputService:GetLastInputType()]
	local lastInputDevice, setLastInputDevice = React.useState(initialValue)
	React.useEffect(function()
		local connection = UserInputService.LastInputTypeChanged:Connect(function(inputType)
			local inputDevice = INPUT_TYPE_TO_DEVICE[inputType]
			if inputDevice ~= lastInputDevice then
				setLastInputDevice(inputDevice)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return lastInputDevice
end

return useLastInputDevice
