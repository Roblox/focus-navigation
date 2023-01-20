--!strict
local Packages = script.Parent.Parent
local EventPropagationService = require(Packages.EventPropagation)
local ZenObservable = require(Packages.ZenObservable)
local Observable = ZenObservable.Observable

local types = require(script.Parent.types)
type InputDevice = types.InputDevice
type EventMap = types.EventMap
type EventData = types.EventData

type EventPhase = EventPropagationService.EventPhase
type Event<T> = EventPropagationService.Event<T>
type EventPropagationService<T> = EventPropagationService.EventPropagationService<T>
type EventHandlerMap = EventPropagationService.EventHandlerMap<EventData>

export type EventHandler = (Event<EventData>) -> ()

export type FocusNavigationService = {
	registerEventMap: (self: FocusNavigationService, GuiObject, EventMap) -> (),
	deregisterEventMap: (self: FocusNavigationService, GuiObject, EventMap) -> (),
	registerEventHandlers: (self: FocusNavigationService, GuiObject, EventHandlerMap) -> (),
	deregisterEventHandlers: (self: FocusNavigationService, GuiObject, EventHandlerMap) -> (),
	registerEventHandler: (self: FocusNavigationService, GuiObject, string, EventHandler, EventPhase?) -> (),
	deregisterEventHandler: (self: FocusNavigationService, GuiObject, string, EventHandler, EventPhase?) -> (),
	focusGuiObject: (self: FocusNavigationService, GuiObject, boolean) -> (),
	teardown: (self: FocusNavigationService) -> (),

	activeInputDevice: ZenObservable.Observable<InputDevice>,
	activeEventMap: ZenObservable.Observable<EventMap>,
	focusedGuiObject: ZenObservable.Observable<GuiObject?>,
}

type FocusNavigationServicePrivate = {
	_eventPropagationService: EventPropagationService<EventData>,
	_eventMapByInstance: { [Instance]: EventMap },
	_guiService: GuiService,
	_focusProperty: "SelectedObject" | "SelectedCoreObject",
	_engineEventConnections: { RBXScriptConnection },

	_lastFocused: GuiObject?,
	_silentFocusTarget: GuiObject?,
	_silentBlurTarget: GuiObject?,

	_connectToInputEvents: (FocusNavigationServicePrivate, UserInputService) -> (),
	_fireInputEvent: (FocusNavigationServicePrivate, GuiObject, InputObject) -> (),
	_getFocusedGuiObject: (FocusNavigationServicePrivate) -> GuiObject?,
	_updateActiveEventMap: (FocusNavigationServicePrivate) -> (),

	registerEventMap: (self: FocusNavigationServicePrivate, GuiObject, EventMap) -> (),
	deregisterEventMap: (self: FocusNavigationServicePrivate, GuiObject, EventMap) -> (),
	registerEventHandlers: (self: FocusNavigationServicePrivate, GuiObject, EventHandlerMap) -> (),
	deregisterEventHandlers: (self: FocusNavigationServicePrivate, GuiObject, EventHandlerMap) -> (),
	registerEventHandler: (self: FocusNavigationServicePrivate, GuiObject, string, EventHandler, EventPhase?) -> (),
	deregisterEventHandler: (self: FocusNavigationServicePrivate, GuiObject, string, EventHandler, EventPhase?) -> (),
	focusGuiObject: (self: FocusNavigationServicePrivate, GuiObject, boolean) -> (),
	teardown: (self: FocusNavigationServicePrivate) -> (),

	activeInputDevice: ZenObservable.Observable<InputDevice>,
	activeEventMap: ZenObservable.Observable<EventMap>,
	focusedGuiObject: ZenObservable.Observable<GuiObject?>,
}

type FocusNavigationServiceStatics = {
	new: (boolean, UserInputService?, GuiService?) -> FocusNavigationService,
}

local FocusNavigationService = {} :: FocusNavigationServicePrivate & FocusNavigationServiceStatics;
(FocusNavigationService :: any).__index = FocusNavigationService

function FocusNavigationService.new(isCoreGui: boolean, userInputService: UserInputService?, guiService: GuiService?)
	local resolvedGuiService: GuiService = guiService or game:GetService("GuiService")
	local focusProperty = if isCoreGui then "SelectedCoreObject" else "SelectedObject"
	local self: FocusNavigationServicePrivate = setmetatable({
		_eventPropagationService = EventPropagationService.new(),
		_guiService = resolvedGuiService,

		_eventMapByInstance = setmetatable({}, { __mode = "k" }),
		_engineEventConnections = {},

		_focusProperty = focusProperty,
		_lastFocused = (resolvedGuiService :: any)[focusProperty],
		_silentFocusTarget = nil,
		_silentBlurTarget = nil,

		activeInputDevice = Observable.new(function(_observer)
			-- TODO: observer logic
		end),
		activeEventMap = Observable.new(function(_observer)
			-- TODO: observer logic
		end),
		focusedInstance = Observable.new(function(_observer)
			-- TODO: observer logic
		end),
	}, FocusNavigationService) :: any

	self:_connectToInputEvents(userInputService or game:GetService("UserInputService"))

	return (self :: any) :: FocusNavigationService
end

function FocusNavigationService:_getFocusedGuiObject(): GuiObject?
	return (self._guiService :: any)[self._focusProperty]
end

function FocusNavigationService:_fireInputEvent(focusedInstance: Instance, input: InputObject)
	local eventsForInstance = self._eventMapByInstance[focusedInstance]
	local event = if eventsForInstance and input.KeyCode then eventsForInstance[input.KeyCode] else nil
	if event then
		self._eventPropagationService:propagateEvent(focusedInstance, event, {
			Delta = input.Delta,
			KeyCode = input.KeyCode,
			Position = input.Position,
			-- TODO: We may need to do this differently somehow, depending on
			-- how deferred lua solutions change
			UserInputState = input.UserInputState,
			-- TODO: Should we simplify this, or provide it as is?
			UserInputType = input.UserInputType,
		}, false)
	end
end

function FocusNavigationService:_connectToInputEvents(userInputService: UserInputService)
	-- Which inputs are we connecting to? Does it need to be part of the phases?
	local function forwardInputEvent(input, wasProcessed)
		-- TODO: I don't think we want to be listening to any already-captured
		-- events (like the left click from clicking a button with a mouse), but
		-- maybe the user needs more control?
		local currentFocus = self:_getFocusedGuiObject()
		if currentFocus and not wasProcessed then
			self:_fireInputEvent(currentFocus, input)
		end
	end
	table.insert(self._engineEventConnections, userInputService.InputBegan:Connect(forwardInputEvent))
	table.insert(self._engineEventConnections, userInputService.InputChanged:Connect(forwardInputEvent))
	table.insert(self._engineEventConnections, userInputService.InputEnded:Connect(forwardInputEvent))

	local function onFocusChanged()
		local previousFocus = self._lastFocused
		local nextFocus = self:_getFocusedGuiObject()

		-- TODO: what happens if a selection change happens in response to a blur event?
		if previousFocus then
			local silent = self._silentBlurTarget == previousFocus
			self._eventPropagationService:propagateEvent(previousFocus, "blur", nil, silent)
			self._silentBlurTarget = nil
		end
		if nextFocus then
			local silent = nextFocus == self._silentFocusTarget
			self._eventPropagationService:propagateEvent(nextFocus, "focus", nil, silent)
			self._silentFocusTarget = nil
		end

		self._lastFocused = nextFocus
	end
	table.insert(
		self._engineEventConnections,
		self._guiService:GetPropertyChangedSignal(self._focusProperty):Connect(onFocusChanged)
	)
end

function FocusNavigationService:registerEventMap(guiObject: GuiObject, eventMap: EventMap)
	local updatedEventMap: EventMap = self._eventMapByInstance[guiObject] or {}
	for keyCode, name in eventMap do
		-- TODO: Warnings
		-- if updatedEventMap[keyCode] and updatedEventMap[keyCode] ~= name then
		-- end
		updatedEventMap[keyCode] = name
	end
	self._eventMapByInstance[guiObject] = updatedEventMap
end

function FocusNavigationService:deregisterEventMap(guiObject: GuiObject, eventMap: EventMap)
	local updatedEventMap: EventMap = self._eventMapByInstance[guiObject] or {}
	for keyCode, name in eventMap do
		if updatedEventMap[keyCode] == name then
			updatedEventMap[keyCode] = nil
			-- TODO: warnings
			-- else
			-- warn("cannot deregister non-matching event...")
		end
	end
	self._eventMapByInstance[guiObject] = updatedEventMap
end

function FocusNavigationService:registerEventHandler(
	guiObject: GuiObject,
	eventName: string,
	eventHandler: EventHandler,
	phase: EventPhase?
)
	self._eventPropagationService:registerEventHandler(guiObject, eventName, eventHandler, phase)
end

function FocusNavigationService:deregisterEventHandler(
	guiObject: GuiObject,
	eventName: string,
	eventHandler: EventHandler,
	phase: EventPhase?
)
	self._eventPropagationService:deregisterEventHandler(guiObject, eventName, eventHandler, phase)
end

function FocusNavigationService:registerEventHandlers(guiObject: GuiObject, eventHandlers: EventHandlerMap)
	self._eventPropagationService:registerEventHandlers(guiObject, eventHandlers)
end

function FocusNavigationService:deregisterEventHandlers(guiObject: GuiObject, eventHandlers: EventHandlerMap)
	self._eventPropagationService:deregisterEventHandlers(guiObject, eventHandlers)
end

function FocusNavigationService:focusGuiObject(guiObject: GuiObject, silent: boolean)
	-- TODO: Should we warn if trying to focus something that's not under the
	-- correct gui target? e.g. warn/error when trying to focus something under
	-- PlayerGui if core ui is enabled?
	if silent then
		-- If we've silenced the event, we need to identify which guiObjects
		-- we're going to and from so that we can respond accordingly
		self._silentBlurTarget = self:_getFocusedGuiObject()
		self._silentFocusTarget = guiObject :: GuiObject?
	else
		-- Otherwise, clear the state to make sure we're somewhat resilient to
		-- weird interaction sequences or attempts to refocus during callbacks
		self._silentBlurTarget = nil
		self._silentFocusTarget = nil
	end
	(self._guiService :: any)[self._focusProperty] = guiObject
end

function FocusNavigationService:teardown()
	for _, connection in self._engineEventConnections do
		connection:Disconnect()
	end
end

return FocusNavigationService
