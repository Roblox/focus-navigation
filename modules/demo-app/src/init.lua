--!strict
local Packages = script.Parent
local ReactRoblox = require(Packages.ReactRoblox)
local React = require(Packages.React)

local App = require(script.App)

local function mountApp(container)
	local root = ReactRoblox.createRoot(container)

	root:render(React.createElement(App))

	return root
end

return {
	App = App,
	mountApp = mountApp,
}
