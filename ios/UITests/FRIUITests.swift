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
        XCTAssertEqual(app.textFields["dailyPouches"].value as? String, "10")
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

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<24 {
            if element.isHittable { break }
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
        XCTAssertTrue(element.isHittable)
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
        app.buttons["tab-Fremskridt"].tap()
        let yesterday = app.buttons[dayID(offset: -1)]
        reveal(yesterday, in: app)
        XCTAssertTrue(yesterday.label.contains("Ikke bekræftet")); yesterday.tap()
        app.buttons["confirmDay"].tap()
        XCTAssertTrue(app.staticTexts["confirmedDaysCount"].label.contains("1 bekræftet dag"))
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        app.buttons["tab-Fremskridt"].tap(); reveal(yesterday, in: app)
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
        app.buttons["onboardingNext"].tap(); app.buttons["onboardingNext"].tap()
        let daily = app.textFields["dailyPouches"]
        daily.tap(); daily.typeText(XCUIKeyboardKey.delete.rawValue + XCUIKeyboardKey.delete.rawValue + "17")
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        XCTAssertTrue(app.textFields["dailyPouches"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["dailyPouches"].value as? String, "17")
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
        app.launch(); app.buttons["tab-Min plan"].tap()
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
        app.buttons["tab-Fremskridt"].tap()
        let yesterday = app.buttons[dayID(offset: -1)]; reveal(yesterday, in: app); yesterday.tap()
        let confirm = app.buttons["confirmDay"]; reveal(confirm, in: app); confirm.tap()
        XCTAssertFalse(app.buttons["confirmDay"].exists)
    }

    @MainActor func testPlanEditingPersistsAcrossLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch(); app.buttons["tab-Min plan"].tap(); app.buttons["editPlan"].tap()
        app.buttons["Flere penge"].tap()
        let field = app.textFields["copingAction"]; reveal(field, in: app)
        field.tap()
        field.typeText("Mit nye skridt: ")
        let edited = field.value as? String ?? ""
        XCTAssertTrue(edited.contains("Mit nye skridt:"))
        let save = app.buttons["savePlan"]; reveal(save, in: app); save.tap()
        XCTAssertTrue(app.buttons["editPlan"].waitForExistence(timeout: 5))
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        app.buttons["tab-Min plan"].tap()
        XCTAssertTrue(app.staticTexts["Flere penge."].exists)
        XCTAssertTrue(app.staticTexts[edited].exists)
    }

    @MainActor func testLocalBackupRestoresAndDismissesStaleEditors() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]
        app.launch(); app.buttons["tab-Fremskridt"].tap()
        let yesterday = app.buttons[dayID(offset: -1)]; reveal(yesterday, in: app); yesterday.tap()
        app.buttons["confirmDay"].tap()
        app.buttons["settings"].tap()
        let data = app.buttons["dataSettings"]; reveal(data, in: app); data.tap()
        let recover = app.buttons["recoverBackup"]; reveal(recover, in: app); recover.tap()
        let use = app.buttons["confirmImport"]; reveal(use, in: app); use.tap()
        app.buttons["Gendan denne plan"].tap()
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveSettings"].exists)
        app.buttons["tab-Fremskridt"].tap(); reveal(yesterday, in: app)
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
        let tin = app.textFields["tinPouches"]
        XCTAssertTrue(tin.waitForExistence(timeout: 5))
        tin.tap()
        tin.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2) + "0")
        XCTAssertFalse(app.buttons["onboardingNext"].isEnabled)
        tin.typeText(XCUIKeyboardKey.delete.rawValue + "20")
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
        XCTAssertTrue(app.buttons["savingsCounter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savingsCounter"].label.contains("372,"))
        app.buttons["tab-Fremskridt"].tap()
        let undo = app.buttons["Fortryd"]
        for _ in 0..<8 where !undo.isHittable { app.swipeUp() }
        XCTAssertTrue(undo.exists)
        undo.tap()
        app.buttons["tab-I dag"].tap()
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
        app.buttons["tab-Min plan"].tap(); app.buttons["editPlan"].tap()
        let coffee = app.textFields["action-Til kaffen"]; reveal(coffee, in: app)
        coffee.tap(); coffee.typeText("Tag tyggegummi frem.")
        let save = app.buttons["savePlan"]; reveal(save, in: app); save.tap()
        app.buttons["tab-I dag"].tap(); app.buttons["cravingHelp"].tap()
        app.buttons["cravingSituation"].tap(); app.buttons["Til kaffen"].tap()
        XCTAssertEqual(app.staticTexts["activeCopingAction"].label, "Tag tyggegummi frem.")
        app.buttons["startPause"].tap()
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        app.buttons["cravingHelp"].tap()
        XCTAssertEqual(app.staticTexts["activeCopingAction"].label, "Tag tyggegummi frem.")
        app.buttons["finishPause"].tap()
        app.buttons["Min valgte handling hjalp"].tap()
        app.buttons["saveWinFeedback"].tap()
        app.buttons["tab-Fremskridt"].tap()
        let history = app.buttons["openJournal"]; reveal(history, in: app); history.tap()
        XCTAssertTrue(app.staticTexts["Til kaffen · Tag tyggegummi frem."].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "Du kom videre fra trangen").count, 1)
        let edit = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editWin-'")).firstMatch
        reveal(edit, in: app); edit.tap()
        let action = app.textFields["winAction"]; action.tap(); action.typeText(" Det virkede for mig.")
        app.buttons["saveWinFeedback"].tap()
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        app.buttons["tab-Fremskridt"].tap(); reveal(history, in: app); history.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Det virkede for mig.'")).firstMatch.exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "Du kom videre fra trangen").count, 1)
    }

    @MainActor func testRecordedPouchCanBeCorrectedWithoutDuplicate() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-demo"]; app.launch()
        app.buttons["logLapse"].tap()
        let confirm = app.buttons["confirmLapse"]; reveal(confirm, in: app); confirm.tap()
        app.buttons["tab-Fremskridt"].tap()
        let history = app.buttons["openJournal"]; reveal(history, in: app); history.tap()
        let edit = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editLapse-'")).firstMatch
        edit.tap()
        app.steppers["lapseCount"].buttons.element(boundBy: 1).tap()
        reveal(confirm, in: app); confirm.tap()
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '2 poser ·'")).count, 1)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editLapse-'")).count, 1)
    }

}
