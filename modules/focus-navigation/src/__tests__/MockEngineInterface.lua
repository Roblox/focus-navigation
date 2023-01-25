--!strict
local Packages = script.Parent.Parent.Parent
local Collections = require(Packages.Dev.Collections)
local JestGlobals = require(Packages.Dev.JestGlobals)

local types = require(script.Parent.Parent.types)
type InputEvent = types.InputEvent
type EngineInterface = types.EngineInterface

local Set = Collections.Set
local jest = JestGlobals.jest

type SpyFn = typeof(jest.fn())

type EventHandler = (InputEvent) -> ()
type Connections<T> = Collections.Set<T>
type MockInputSignal<T> = {
	connections: Connections<T>,
	disconnectSpy: SpyFn,
	signal: RBXScriptSignal,
}

local function createMockInputSignal<T>(): MockInputSignal<T>
	local connections: Connections<T> = Set.new()
	local disconnectSpy = jest.fn()

	return {
		connections = connections,
		disconnectSpy = disconnectSpy,
		signal = {
			Connect = jest.fn(function(_, handler: T)
				connections:add(handler)

				return {
					Disconnect = function(...)
						connections:delete(handler)
						disconnectSpy(...)
					end,
				}
			end),
		} :: any,
	}
end

type MockEngineInterface = EngineInterface & {
	mock: {
		SelectionChangedDisconnected: SpyFn,
		InputBeganDisconnected: SpyFn,
		InputChangedDisconnected: SpyFn,
		InputEndedDisconnected: SpyFn,
	},
	simulateInput: (InputEvent) -> (),
}

local MockEngineInterface = {}

function MockEngineInterface.new(): MockEngineInterface
	local selectionChanged = createMockInputSignal()
	local inputBegan = createMockInputSignal()
	local inputChanged = createMockInputSignal()
	local inputEnded = createMockInputSignal()

	local currentSelection = nil

	return {
		getSelection = function()
			return currentSelection
		end,
		setSelection = function(guiObject)
			currentSelection = guiObject
			selectionChanged.connections:forEach(function(handler)
				handler()
			end)
		end,

		SelectionChanged = selectionChanged.signal,
		InputBegan = inputBegan.signal,
		InputChanged = inputChanged.signal,
		InputEnded = inputEnded.signal,

		_inputBeganConnections = inputBegan.connections,
		_inputChangedConnections = inputChanged.connections,
		_inputEndedConnections = inputEnded.connections,

		mock = {
			SelectionChangedDisconnected = selectionChanged.disconnectSpy,
			InputBeganDisconnected = inputBegan.disconnectSpy,
			InputChangedDisconnected = inputChanged.disconnectSpy,
			InputEndedDisconnected = inputEnded.disconnectSpy,
		},
		simulateInput = function(event: InputEvent)
			if event.UserInputState == Enum.UserInputState.Begin then
				inputBegan.connections:forEach(function(handler)
					handler(event)
				end)
			elseif event.UserInputState == Enum.UserInputState.Change then
				inputChanged.connections:forEach(function(handler)
					handler(event)
				end)
			elseif event.UserInputState == Enum.UserInputState.End then
				inputEnded.connections:forEach(function(handler)
					handler(event)
				end)
			end
		end,
	}
end

return MockEngineInterface
