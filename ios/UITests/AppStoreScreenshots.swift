import XCTest

/// Captures App Store screenshots from isolated demo data. Skipped unless run through
/// `release/screenshots.sh`, which sets TEST_RUNNER_SCREENSHOT_DIR.
final class AppStoreScreenshots: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        guard let path = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_SCREENSHOT_DIR to capture App Store screenshots.")
        }
        directory = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        continueAfterFailure = false
    }

    @MainActor private func capture(_ name: String) throws {
        sleep(1) // Let sheet and counter animations settle.
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: directory.appendingPathComponent("\(name).png"))
    }

    @MainActor private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 where !element.isHittable { app.swipeUp() }
    }

    @MainActor func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 10))
        try capture("01-home")

        app.buttons["cravingHelp"].tap()
        XCTAssertTrue(app.buttons["startPause"].waitForExistence(timeout: 5))
        try capture("02-craving")
        app.buttons["Luk"].firstMatch.tap()

        app.buttons["tab-Fremskridt"].tap()
        try capture("03-progress")

        app.buttons["tab-Min plan"].tap()
        try capture("04-plan")

        app.buttons["tab-I dag"].tap()
        app.buttons["settings"].tap()
        app.buttons["appearance-dark"].tap()
        app.buttons["Luk"].firstMatch.tap()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        try capture("05-home-dark")

        app.terminate()
        app.launchArguments = ["-ui-testing", "-reset-state"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 10))
        try capture("06-onboarding")
    }
}
