--!strict
type PropMap = {
	[string]: any,
}
type TreeSpec = {
	-- Luau types don't express tuples well, so this will have to do
	[string]: { string | Instance | PropMap | nil },
}
type InstanceMap = { [string]: GuiObject }

--[[
	Accepts a set of information and uses it to create a tree of GuiObjects for
	testing against. Pass in data using the following format:
	{
		[name: string]: { class: string, parent: string | GuiObject?, properties: { [string]: any }? }
	}

	For example:
	{
		root = { "ScreenGui", game:GetService("Players").LocalPlayer.PlayerGui },
		Container = { "Frame", "root" },
		ButtonA = { "TextButton", "Container", { Text = "Confirm" } },
		ButtonB = { "TextButton", "Container", { Text = "Cancel" } },
	}
]]
return function(treeSpec: TreeSpec): InstanceMap
	local objects = {}

	-- Create all Instances first
	for name, spec in treeSpec do
		assert(typeof(spec[1]) == "string", 'First member of each array must be the Instance Class (e.g. "Frame")')
		-- Types: no easy way to specify "the set of instance types that
		-- Instance.new accepts"
		objects[name] = (Instance.new(spec[1] :: any) :: any) :: GuiObject
		objects[name].Name = name
	end

	for name, spec in treeSpec do
		local parent = spec[2]
		assert(
			typeof(parent) == "string" or typeof(parent) == "Instance",
			"Second member of each array must be either the name of another defined Instance or an Instance"
		)

		objects[name].Parent = if typeof(parent) == "string" then objects[parent] else parent

		local properties = spec[3]
		if properties then
			assert(typeof(properties) == "table", "Third member of each array must be a table of properties (or nil)")
			for propertyName, value in properties :: any do
				-- Types: we need to pretend the Instance is an arbitrary table
				((objects[name] :: any) :: PropMap)[propertyName] = value
			end
		end
	end

	return objects
end
