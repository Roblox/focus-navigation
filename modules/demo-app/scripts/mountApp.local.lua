local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DemoApp = require(ReplicatedStorage.Packages.DemoApp)

local PlayerGui = Players.LocalPlayer.PlayerGui

local container = Instance.new("Folder")
container.Parent = PlayerGui

DemoApp.mountApp(container)
