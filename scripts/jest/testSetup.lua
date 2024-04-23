--!strict
local Packages = script.Parent.Parent
local JestGlobals = require(script.Parent.ReactFocusNavigation.Dev.JestGlobals)

local beforeAll = JestGlobals.beforeAll
local expect = JestGlobals.expect

local Utils = require(Packages.FocusNavigationUtils)

local function toWarnDev(_, callback: () -> (any), expected: string | { string })
	if _G.__DEV__ then
		local expectedMessages
		-- Warn about incorrect usage of matcher.
		if typeof(expectedMessages) == "string" then
			expectedMessages = { expected :: string }
		else
			expectedMessages = table.clone(expected) :: { string }
		end

		local unexpectedWarnings = {}

		Utils.mockableWarn.mock(function(warning)
			local nextExpected = expectedMessages[1]
			if nextExpected and string.find(warning, nextExpected) then
				table.remove(expectedMessages, 1)
			else
				table.insert(unexpectedWarnings, warning)
			end
		end)

		-- Catch errors thrown by the callback,
		-- But only rethrow them if all test expectations have been satisfied.
		-- Otherwise an Error in the callback can mask a failed expectation,
		-- and result in a test that passes when it shouldn't.
		local caughtError
		local ok, errorMessage = pcall(callback)
		if not ok then
			caughtError = errorMessage
		end

		Utils.mockableWarn.unmock()

		-- Any unexpected Errors thrown by the callback should fail the test.
		-- This should take precedence since unexpected errors could block warnings.
		if caughtError then
			error(caughtError, 3)
		end

		-- Any unexpected warnings should be treated as a failure.
		if #unexpectedWarnings > 0 then
			return {
				message = function()
					return string.format("Unexpected warning was recorded:\n %s\n  ", unexpectedWarnings[1])
				end :: (() -> string)?,
				pass = false,
			}
		end

		-- Any remaining messages indicate a failed expectations.
		if #expectedMessages > 0 then
			return {
				message = function()
					return string.format("Expected warning was not recorded:\n %s\n  ", expectedMessages[1])
				end,
				pass = false,
			}
		end
	end
	return { pass = true }
end

beforeAll(function()
	expect.extend({
		toWarnDev = toWarnDev,
	})
end)
