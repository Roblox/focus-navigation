--!strict
local Packages = script.Parent.Parent
local FocusNavigation = require(Packages.FocusNavigation)
type EventHandler = FocusNavigation.EventHandler

local function compose(...: ...EventHandler): EventHandler?
	-- TODO: Figure out how we want to compose, and with what rules; can one
	-- handler "sink" the input so that the next doesn't get it? or does compose
	-- always mean all member handlers will be honored?
	return nil
end

return compose
