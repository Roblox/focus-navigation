--!strict

-- TODO: Remove this and replace with regular mock timers when jest supports
-- mocking engine steps like Heartbeat
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local jest = JestGlobals.jest

local FRAME_DURATION_MS = 1000 / 60
local stepCallbacks: { [(number) -> ()]: boolean } = {}
local mockTime = 0

local function advanceTimersByTime(ms)
	local nextFrame = math.floor(mockTime / FRAME_DURATION_MS) + 1
	local endFrame = math.floor((mockTime + ms) / FRAME_DURATION_MS)

	if endFrame >= nextFrame then
		-- starting sub-frame interval
		jest.advanceTimersByTime((nextFrame * FRAME_DURATION_MS) - mockTime)
	end

	mockTime += ms
	for _ = nextFrame, endFrame do
		for callback, _ in pairs(stepCallbacks) do
			callback(FRAME_DURATION_MS)
		end
		jest.advanceTimersByTime(FRAME_DURATION_MS)
	end

	-- ending sub-frame interval
	jest.advanceTimersByTime(mockTime - (endFrame * FRAME_DURATION_MS))
end

return {
	Connect = function(_, callback)
		stepCallbacks[callback] = true
		return {
			Disconnect = function()
				stepCallbacks[callback] = nil
			end,
		}
	end,
	advanceTimersByTime = advanceTimersByTime,
	FRAME_DURATION_MS = FRAME_DURATION_MS,
}
