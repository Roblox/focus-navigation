--!strict
local Packages = script.Parent.Parent.Parent
local Collections = require(Packages.Dev.Collections)
local JestGlobals = require(Packages.Dev.JestGlobals)

local types = require(script.Parent.Parent.types)
type InputEvent = types.InputEvent

local Set = Collections.Set
local jest = JestGlobals.jest

type SpyFn = typeof(jest.fn())

type EventHandler = (InputEvent) -> ()
type Connections = Collections.Set<EventHandler>
type MockInputSignal = {
	connections: Connections,
	disconnectSpy: SpyFn,
	signal: {
		Connect: SpyFn,
	},
}

local function createMockInputSignal(): MockInputSignal
	local connections: Connections = Set.new()
	local disconnectSpy = jest.fn()

	return {
		connections = connections,
		disconnectSpy = disconnectSpy,
		signal = {
			Connect = jest.fn(function(_, handler)
				connections:add(handler)

				return {
					Disconnect = function(...)
						connections:delete(handler)
						disconnectSpy(...)
					end,
				}
			end),
		},
	}
end

type MockUserInputService = {
	InputBegan: { Connect: SpyFn },
	InputChanged: { Connect: SpyFn },
	InputEnded: { Connect: SpyFn },
	mock: {
		InputBeganDisconnected: SpyFn,
		InputChangedDisconnected: SpyFn,
		InputEndedDisconnected: SpyFn,
	},
	simulateInput: (MockUserInputService, InputEvent) -> (),
}

local MockUserInputService = {}
MockUserInputService.__index = MockUserInputService

function MockUserInputService.new()
	local inputBegan = createMockInputSignal()
	local inputChanged = createMockInputSignal()
	local inputEnded = createMockInputSignal()
	local self = setmetatable({
		InputBegan = inputBegan.signal,
		InputChanged = inputChanged.signal,
		InputEnded = inputEnded.signal,

		_inputBeganConnections = inputBegan.connections,
		_inputChangedConnections = inputChanged.connections,
		_inputEndedConnections = inputEnded.connections,

		mock = {
			InputBeganDisconnected = inputBegan.disconnectSpy,
			InputChangedDisconnected = inputChanged.disconnectSpy,
			InputEndedDisconnected = inputEnded.disconnectSpy,
		},
	}, MockUserInputService)

	return (self :: any) :: MockUserInputService
end

function MockUserInputService:simulateInput(event: InputEvent)
	if event.UserInputState == Enum.UserInputState.Begin then
		self._inputBeganConnections:forEach(function(handler)
			handler(event)
		end)
	elseif event.UserInputState == Enum.UserInputState.Change then
		self._inputChangedConnections:forEach(function(handler)
			handler(event)
		end)
	elseif event.UserInputState == Enum.UserInputState.End then
		self._inputEndedConnections:forEach(function(handler)
			handler(event)
		end)
	end
end

return MockUserInputService
