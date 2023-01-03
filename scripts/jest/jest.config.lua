return {
	displayName = "FocusNavigation",
	testMatch = { "**/__tests__/**/*.spec" },
	setupFilesAfterEnv = { script.Parent.testSetup },
	collectCoverage = true,
	coverageReporters = {"text"}
}
