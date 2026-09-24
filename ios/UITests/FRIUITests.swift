import XCTest

final class FRIUITests: XCTestCase {
    @MainActor func testAppearanceSavesImmediatelyAndSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch()
        app.buttons["settings"].tap()
        XCTAssertEqual(app.buttons["appearance-light"].value as? String, "Valgt")
        // No save action or sheet dismissal is needed to retain appearance.
        app.buttons["appearance-dark"].tap()
        XCTAssertEqual(app.buttons["appearance-dark"].value as? String, "Valgt")
        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        app.buttons["settings"].tap()
        XCTAssertEqual(app.buttons["appearance-dark"].value as? String, "Valgt")
        XCTAssertEqual(app.staticTexts["dailyPouches"].label, "10")
        app.buttons["appearance-system"].tap()
        XCTAssertTrue(app.staticTexts["Følger telefonens lyse eller mørke udseende."].exists)
        app.terminate(); app.launch()
        app.buttons["settings"].tap()
        XCTAssertEqual(app.buttons["appearance-system"].value as? String, "Valgt")
        app.buttons["appearance-light"].tap()
        app.buttons["Luk"].tap()
        XCTAssertTrue(app.buttons["cravingHelp"].exists)
        app.terminate(); app.launch()
        app.buttons["settings"].tap()
        XCTAssertEqual(app.buttons["appearance-light"].value as? String, "Valgt")
    }

    /// The glass tab bar minimises while scrolling down; scroll back up to expand it.
    @MainActor func tab(_ name: String, in app: XCUIApplication) -> XCUIElement {
        let button = app.tabBars.buttons[name]
        for _ in 0..<3 where !button.isHittable { app.swipeDown() }
        return button
    }

    /// XCUITest reports elements under the keyboard as hittable, so also require them to sit above it.
    @MainActor private func isReachable(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.isHittable else { return false }
        let keyboard = app.keyboards.firstMatch
        return !keyboard.exists || element.frame.maxY <= keyboard.frame.minY
    }

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<24 {
            if isReachable(element, in: app) { break }
            let region = app.scrollViews.firstMatch.frame
            let keyboardTop = app.keyboards.firstMatch.exists ? app.keyboards.firstMatch.frame.minY : app.frame.maxY
            let top = max(region.minY, app.frame.minY + 80)
            let bottom = min(region.maxY, keyboardTop, app.frame.maxY - 90)
            let height = max(100, bottom - top)
            let above = element.exists && element.frame.maxY < top
            let startY = top + height * (above ? 0.25 : 0.8)
            let endY = top + height * (above ? 0.8 : 0.25)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            origin.withOffset(CGVector(dx: app.frame.midX, dy: startY)).press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: app.frame.midX, dy: endY)))
        }
        XCTAssertTrue(isReachable(element, in: app))
    }

    private func dayID(offset: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        let date = calendar.date(byAdding: .day, value: offset, to: Date())!
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "day-%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    @MainActor func testConfirmedDaySurvivesRelaunchAndCanBeUndone() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]; app.launch()
        tab("Fremskridt", in: app).tap()
        let yesterday = app.buttons[dayID(offset: -1)]
        reveal(yesterday, in: app)
        XCTAssertTrue(yesterday.label.contains("Ikke bekræftet")); yesterday.tap()
        app.buttons["confirmDay"].tap()
        XCTAssertTrue(app.staticTexts["confirmedDaysCount"].label.contains("1 bekræftet dag"))
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        tab("Fremskridt", in: app).tap(); reveal(yesterday, in: app)
        XCTAssertTrue(yesterday.label.contains("Bekræftet uden poser")); yesterday.tap()
        app.buttons["unconfirmDay"].tap()
        XCTAssertTrue(yesterday.label.contains("Ikke bekræftet"))
        app.buttons[dayID(offset: 0)].tap()
        XCTAssertFalse(app.buttons["confirmDay"].exists)
    }

    @MainActor func testOnboardingDraftResumesAfterTermination() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state"]
        app.launch()
        let next = app.buttons["onboardingNext"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()
        // The welcome footer moves when the backup button disappears. Wait for
        // the next screen before resolving the second tap's coordinates.
        XCTAssertTrue(app.staticTexts["1 / 5"].waitForExistence(timeout: 5))
        next.tap()
        XCTAssertTrue(app.staticTexts["dailyPouches"].waitForExistence(timeout: 5))
        for _ in 0..<7 { app.buttons["dailyPouches-plus"].tap() }
        XCTAssertEqual(app.staticTexts["dailyPouches"].label, "17")
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        XCTAssertTrue(app.staticTexts["dailyPouches"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["dailyPouches"].label, "17")
    }

    @MainActor func testPauseResumesAfterClosingApp() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch(); app.buttons["cravingHelp"].tap()
        let start = app.buttons["startPause"]; reveal(start, in: app); start.tap()
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        XCTAssertTrue(app.buttons["cravingHelp"].label.contains("Fortsæt"))
        app.buttons["cravingHelp"].tap()
        XCTAssertFalse(app.buttons["startPause"].exists)
        let finish = app.buttons["finishPause"]; reveal(finish, in: app); finish.tap()
        app.buttons["skipWinFeedback"].tap()
        XCTAssertTrue(app.buttons["cravingHelp"].label.contains("Jeg har lyst"))
    }

    @MainActor func testReminderEnablePersistsAndCanBeDisabled() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch(); tab("Min plan", in: app).tap()
        let settings = app.buttons["reminderSettings"]; reveal(settings, in: app); settings.tap()
        let enable = app.buttons["enableReminder"]; reveal(enable, in: app); enable.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Tillad"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
        else if springboard.buttons["Allow"].exists { springboard.buttons["Allow"].tap() }
        XCTAssertTrue(app.buttons["disableReminder"].waitForExistence(timeout: 8))
        app.buttons["Luk"].tap()
        reveal(settings, in: app); settings.tap()
        let disable = app.buttons["disableReminder"]; reveal(disable, in: app); disable.tap()
        XCTAssertFalse(app.buttons["disableReminder"].exists)
        XCTAssertTrue(app.staticTexts["Du har ingen aktiv daglig påmindelse."].exists)
    }

    @MainActor func testLargeTypeCoreFlowsRemainUsable() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let help = app.buttons["cravingHelp"]; reveal(help, in: app); help.tap()
        let start = app.buttons["startPause"]; reveal(start, in: app); start.tap()
        let finish = app.buttons["finishPause"]; reveal(finish, in: app); finish.tap()
        let skip = app.buttons["skipWinFeedback"]; reveal(skip, in: app); skip.tap()
        tab("Fremskridt", in: app).tap()
        let yesterday = app.buttons[dayID(offset: -1)]; reveal(yesterday, in: app); yesterday.tap()
        let confirm = app.buttons["confirmDay"]; reveal(confirm, in: app); confirm.tap()
        XCTAssertFalse(app.buttons["confirmDay"].exists)
    }

    @MainActor func testPlanEditingPersistsAcrossLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch(); tab("Min plan", in: app).tap(); app.buttons["editPlan"].tap()
        app.buttons["Flere penge"].tap()
        let field = app.textFields["copingAction"]; reveal(field, in: app)
        field.tap()
        field.typeText("Mit nye skridt: ")
        let edited = field.value as? String ?? ""
        XCTAssertTrue(edited.contains("Mit nye skridt:"))
        let save = app.buttons["savePlan"]; reveal(save, in: app); save.tap()
        XCTAssertTrue(app.buttons["editPlan"].waitForExistence(timeout: 5))
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        tab("Min plan", in: app).tap()
        XCTAssertTrue(app.staticTexts["Flere penge."].exists)
        XCTAssertTrue(app.staticTexts[edited].exists)
    }

    @MainActor func testLongGeneralActionRemainsEditableAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch()
        tab("Min plan", in: app).tap()
        app.buttons["editPlan"].tap()
        let action = app.textFields["copingAction"]
        reveal(action, in: app)
        action.tap()
        action.typeText(String(repeating: "Mit eget skridt. ", count: 18))
        let expected = action.value as? String ?? ""
        XCTAssertGreaterThan(expected.count, 250)
        XCTAssertLessThanOrEqual(expected.count, 500)
        let save = app.buttons["savePlan"]
        reveal(save, in: app)
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.buttons["editPlan"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        tab("Min plan", in: app).tap()
        app.buttons["editPlan"].tap()
        app.buttons["Flere penge"].tap()
        reveal(action, in: app)
        XCTAssertEqual(action.value as? String, expected)
        reveal(save, in: app)
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.staticTexts["Flere penge."].waitForExistence(timeout: 5))
    }

    @MainActor func testLocalBackupRestoresAndDismissesStaleEditors() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch(); tab("Fremskridt", in: app).tap()
        let yesterday = app.buttons[dayID(offset: -1)]; reveal(yesterday, in: app); yesterday.tap()
        app.buttons["confirmDay"].tap()
        app.buttons["settings"].tap()
        let data = app.buttons["dataSettings"]; reveal(data, in: app); data.tap()
        let recover = app.buttons["recoverBackup"]; reveal(recover, in: app); recover.tap()
        let use = app.buttons["confirmImport"]; reveal(use, in: app); use.tap()
        app.buttons["Gendan denne plan"].tap()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveSettings"].exists)
        tab("Fremskridt", in: app).tap(); reveal(yesterday, in: app)
        XCTAssertTrue(yesterday.label.contains("Ikke bekræftet"))
    }

    @MainActor func testSettingsKeepHistoryAndDanishDecimals() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch()
        XCTAssertTrue(app.buttons["settings"].waitForExistence(timeout: 10))
        app.buttons["settings"].tap()
        let price = app.textFields["tinPrice"]
        if !price.isHittable { app.swipeUp() }
        price.tap()
        price.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (price.value as? String ?? "").count) + "50,50")
        app.swipeUp()
        let save = app.buttons["saveSettings"]
        for _ in 0..<4 where !save.isHittable { app.swipeUp() }
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savingsCounter"].label.contains("375"))
        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        app.buttons["settings"].tap()
        XCTAssertEqual(app.textFields["tinPrice"].value as? String, "50,50")
    }

    @MainActor func testOnboardingValidationAndPersistence() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 10))
        app.buttons["onboardingNext"].tap()
        app.buttons["onboardingNext"].tap()
        // Native controls: no keyboard, sensible defaults, and a preset typical tin price.
        XCTAssertTrue(app.staticTexts["tinPouches"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["tinPouches"].label, "20")
        XCTAssertEqual(app.staticTexts["tinPrice"].label, "70")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        app.buttons["tinPouches-plus"].tap(); XCTAssertEqual(app.staticTexts["tinPouches"].label, "21")
        app.buttons["tinPouches-minus"].tap(); XCTAssertEqual(app.staticTexts["tinPouches"].label, "20")
        XCTAssertTrue(app.buttons["onboardingNext"].isEnabled)
        app.buttons["onboardingNext"].tap()
        app.buttons["onboardingNext"].tap()
        app.buttons["onboardingNext"].tap()
        let firstAction = app.textFields["firstCopingAction"]; reveal(firstAction, in: app)
        firstAction.tap()
        firstAction.typeText("Mit eget valg: ")
        let expectedAction = firstAction.value as? String
        XCTAssertTrue(expectedAction?.contains("Mit eget valg:") == true)
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        XCTAssertEqual(firstAction.value as? String, expectedAction)
        app.buttons["onboardingNext"].tap()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboardingNext"].exists)
    }

    @MainActor func testLapseUndoAndCravingJourney() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo", "-fast-timer"]
        app.launch()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["savingsCounter"].label.contains("375"))
        app.buttons["logLapse"].tap()
        let confirm = app.buttons["confirmLapse"]
        if !confirm.isHittable { app.swipeUp() }
        confirm.tap()
        // A new pouch leads to the recommit step before returning home.
        XCTAssertTrue(app.buttons["recommit"].waitForExistence(timeout: 5)); app.buttons["recommit"].tap()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savingsCounter"].label.contains("372,"))
        tab("Fremskridt", in: app).tap()
        let undo = app.buttons["Fortryd"]
        for _ in 0..<8 where !undo.isHittable { app.swipeUp() }
        XCTAssertTrue(undo.exists)
        undo.tap()
        tab("I dag", in: app).tap()
        XCTAssertTrue(app.buttons["savingsCounter"].label.contains("375"))
        app.buttons["cravingHelp"].tap()
        let start = app.buttons["startPause"]
        for _ in 0..<3 where !start.isHittable { app.swipeUp() }
        start.tap()
        let finish = app.buttons["finishPause"]
        for _ in 0..<3 where !finish.isHittable { app.swipeUp() }
        finish.tap()
        app.buttons["skipWinFeedback"].tap()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
    }
    @MainActor func testPersonalSituationAndSuccessfulPauseFeedbackPersist() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]; app.launch()
        tab("Min plan", in: app).tap(); app.buttons["editPlan"].tap()
        let coffee = app.textFields["action-Til kaffen"]; reveal(coffee, in: app)
        coffee.tap(); coffee.typeText("Tag tyggegummi frem.")
        let save = app.buttons["savePlan"]; reveal(save, in: app); save.tap()
        // Wait for the editor sheet (and keyboard) to finish dismissing before using the tab bar.
        let tabReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: tab("I dag", in: app))
        XCTAssertEqual(XCTWaiter().wait(for: [tabReady], timeout: 5), .completed)
        tab("I dag", in: app).tap(); app.buttons["cravingHelp"].tap()
        app.buttons["cravingSituation"].tap(); app.buttons["Til kaffen"].tap()
        XCTAssertEqual(app.staticTexts["activeCopingAction"].label, "Tag tyggegummi frem.")
        app.buttons["startPause"].tap()
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        app.buttons["cravingHelp"].tap()
        XCTAssertEqual(app.staticTexts["activeCopingAction"].label, "Tag tyggegummi frem.")
        app.buttons["finishPause"].tap()
        app.buttons["Min valgte handling hjalp"].tap()
        app.buttons["saveWinFeedback"].tap()
        tab("Fremskridt", in: app).tap()
        let history = app.buttons["openJournal"]; reveal(history, in: app); history.tap()
        XCTAssertTrue(app.staticTexts["Til kaffen · Tag tyggegummi frem."].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "Du kom videre fra trangen").count, 1)
        let edit = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editWin-'")).firstMatch
        reveal(edit, in: app); edit.tap()
        let action = app.textFields["winAction"]; action.tap(); action.typeText(" Det virkede for mig.")
        app.buttons["saveWinFeedback"].tap()
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        tab("Fremskridt", in: app).tap(); reveal(history, in: app); history.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Det virkede for mig.'")).firstMatch.exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "Du kom videre fra trangen").count, 1)
    }

    @MainActor func testRecordedPouchCanBeCorrectedWithoutDuplicate() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]; app.launch()
        app.buttons["logLapse"].tap()
        let confirm = app.buttons["confirmLapse"]; reveal(confirm, in: app); confirm.tap()
        let recommit = app.buttons["recommit"]; XCTAssertTrue(recommit.waitForExistence(timeout: 5)); reveal(recommit, in: app); recommit.tap()
        tab("Fremskridt", in: app).tap()
        let history = app.buttons["openJournal"]; reveal(history, in: app); history.tap()
        let edit = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editLapse-'")).firstMatch
        edit.tap()
        app.steppers["lapseCount"].buttons.element(boundBy: 1).tap()
        reveal(confirm, in: app); confirm.tap()
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '2 poser ·'")).count, 1)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editLapse-'")).count, 1)
    }

}
