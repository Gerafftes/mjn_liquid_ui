import Flutter
import Combine
import SwiftUI
import UIKit
import XCTest

@testable import mjn_liquid_ui

final class RunnerTests: XCTestCase {

  private func popoverArguments(sessionId: Int = 7) -> [String: Any] {
    [
      "sessionId": sessionId,
      "anchor": ["x": 24.0, "y": 100.0, "width": 80.0, "height": 44.0],
      "viewSize": ["width": 390.0, "height": 844.0],
      "content": ["title": "Custom content", "sections": []],
      "options": [
        "width": 280.0, "height": 240.0,
        "arrowDirections": ["up", "down"],
        "compactBehavior": "popover", "animated": false,
        "dismissOnTapOutside": false,
        "backgroundColor": 0xFF123456, "tintColor": 0xFF007AFF,
        "layoutMargins": ["top": 12.0, "left": 14.0, "bottom": 16.0, "right": 18.0],
        "contentPadding": ["top": 2.0, "left": 4.0, "bottom": 6.0, "right": 8.0]
      ]
    ]
  }

  func testPopoverConfigurationAndAvailableSpaceOverridePreferredDimensions() throws {
    let configuration = try XCTUnwrap(AppleLiquidPopoverConfiguration(arguments: popoverArguments()))
    XCTAssertEqual(configuration.width, 280)
    XCTAssertEqual(configuration.height, 240)
    XCTAssertEqual(configuration.arrowDirections, [.up, .down])
    XCTAssertTrue(configuration.forcesPopover)
    XCTAssertEqual(configuration.titleDisplayMode, .inline)
    XCTAssertFalse(configuration.dismissOnTapOutside)
    XCTAssertEqual(configuration.contentPadding.right, 8)
    XCTAssertEqual(configuration.backgroundColor, UIColor(appleLiquidARGB: 0xFF123456))
    XCTAssertEqual(configuration.preferredSize(available: CGSize(width: 200, height: 180), contentHeight: 600),
      CGSize(width: 168, height: 152))

    var args = popoverArguments()
    var options = args["options"] as! [String: Any]
    options.removeValue(forKey: "height")
    options["minHeight"] = 50.0
    options["maxHeight"] = 300.0
    args["options"] = options
    let automaticHeight = try XCTUnwrap(AppleLiquidPopoverConfiguration(arguments: args))
    XCTAssertEqual(automaticHeight.preferredSize(available: CGSize(width: 800, height: 800), contentHeight: 120).height, 128)
  }

  func testPopoverRejectsInvalidDimensionsGeometryAndUnknownDirections() {
    for invalid in [0.0, -1, Double.infinity, Double.nan] {
      var args = popoverArguments()
      var options = args["options"] as! [String: Any]
      options["width"] = invalid
      args["options"] = options
      XCTAssertNil(AppleLiquidPopoverConfiguration(arguments: args))
    }
    let invalidOptions: [[String: Any]] = [
      ["minWidth": 500.0, "maxWidth": 200.0],
      ["arrowDirections": ["diagonal"]],
      ["titleDisplayMode": "unsupported"],
      ["contentPadding": ["top": -1.0, "left": 0.0, "bottom": 0.0, "right": 0.0]]
    ]
    for options in invalidOptions {
      var args = popoverArguments()
      args["options"] = (args["options"] as! [String: Any]).merging(options) { _, new in new }
      XCTAssertNil(AppleLiquidPopoverConfiguration(arguments: args))
    }
    var args = popoverArguments()
    args["anchor"] = ["x": 900.0, "y": 0.0, "width": 80.0, "height": 44.0]
    XCTAssertNil(AppleLiquidPopoverConfiguration(arguments: args))
    args = popoverArguments()
    args["content"] = nil
    XCTAssertNil(AppleLiquidPopoverConfiguration(arguments: args), "No built-in content may be substituted")
  }

  func testPopoverGeometryUsesLogicalViewSpaceAndClipsSourceRect() throws {
    let geometry = try XCTUnwrap(AppleLiquidPopoverGeometry(arguments: popoverArguments()))
    XCTAssertEqual(geometry.sourceRect(in: CGRect(x: 10, y: 20, width: 780, height: 1688)),
      CGRect(x: 58, y: 220, width: 160, height: 88))
    var args = popoverArguments()
    args["anchor"] = ["x": -20.0, "y": 30.0, "width": 80.0, "height": 44.0]
    let clipped = try XCTUnwrap(AppleLiquidPopoverGeometry(arguments: args))
    XCTAssertEqual(clipped.sourceRect(in: CGRect(x: 0, y: 0, width: 390, height: 844)),
      CGRect(x: 0, y: 30, width: 60, height: 44))
  }

  @available(iOS 16.0, *)
  func testPopoverEmptyContentRemainsEmpty() {
    XCTAssertEqual(AppleLiquidPopoverContentRenderer.sectionCount(content: ["title": "", "sections": []]), 0)
    XCTAssertEqual(AppleLiquidPopoverContentRenderer.sectionCount(content: [
      "sections": [["rows": [["type": "text", "title": "Caller supplied"]]]]
    ]), 1)
  }

  @available(iOS 16.0, *)
  func testPopoverNativePresentationDismissalAndSessionIsolation() throws {
    let source = UIViewController()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = source
    window.makeKeyAndVisible()
    defer { source.dismiss(animated: false); window.isHidden = true }
    let presenter = AppleLiquidPopoverPresenter(messenger: SwitchGroupTestMessenger(), sourceProvider: { source })
    var results: [[String: Any]] = []
    presenter.handle(FlutterMethodCall(methodName: "showPopover", arguments: popoverArguments())) { value in
      results.append(value as? [String: Any] ?? [:])
    }
    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    let host = try XCTUnwrap(source.presentedViewController)
    XCTAssertEqual(host.modalPresentationStyle, .popover)
    XCTAssertTrue(host.isModalInPresentation)
    XCTAssertEqual(host.preferredContentSize, CGSize(width: 280, height: 240))
    let popover = try XCTUnwrap(host.popoverPresentationController)
    XCTAssertTrue(popover.sourceView === source.view)
    XCTAssertEqual(popover.permittedArrowDirections, [.up, .down])
    XCTAssertEqual(popover.delegate?.adaptivePresentationStyle?(for: popover, traitCollection: UITraitCollection(horizontalSizeClass: .compact)), UIModalPresentationStyle.none)
    XCTAssertEqual(popover.delegate?.presentationControllerShouldDismiss?(popover), false)

    presenter.handle(FlutterMethodCall(methodName: "showPopover", arguments: popoverArguments(sessionId: 8))) { value in
      XCTAssertEqual((value as? [String: Any])?["status"] as? String, "alreadyShowing")
    }
    presenter.handle(FlutterMethodCall(methodName: "dismissPopover", arguments: ["sessionId": 8])) { value in
      XCTAssertEqual(value as? Bool, false)
    }
    XCTAssertTrue(source.presentedViewController === host)
    var update = popoverArguments()
    update["anchor"] = ["x": 50.0, "y": 160.0, "width": 70.0, "height": 40.0]
    presenter.handle(FlutterMethodCall(methodName: "updateAnchor", arguments: update)) { value in
      XCTAssertEqual(value as? Bool, true)
    }
    XCTAssertEqual(popover.sourceRect.origin.x, 50, accuracy: 0.000001)
    XCTAssertEqual(popover.sourceRect.origin.y, 160, accuracy: 0.000001)
    XCTAssertEqual(popover.sourceRect.width, 70, accuracy: 0.000001)
    XCTAssertEqual(popover.sourceRect.height, 40, accuracy: 0.000001)
    presenter.handle(FlutterMethodCall(methodName: "dismissPopover", arguments: ["sessionId": 7])) { value in
      XCTAssertEqual(value as? Bool, true)
    }
    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?["status"] as? String, "cancelled")
    XCTAssertNil(source.presentedViewController)
    presenter.handle(FlutterMethodCall(methodName: "showPopover", arguments: popoverArguments(sessionId: 9))) { value in
      results.append(value as? [String: Any] ?? [:])
    }
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    XCTAssertNotNil(source.presentedViewController, "A closed session must permit reopening")
    presenter.handle(FlutterMethodCall(methodName: "dismissPopover", arguments: ["sessionId": 9])) { _ in }
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    XCTAssertEqual(results.count, 2)
  }

  private func switchGroupArguments(_ ids: [String], value: Bool = false, tint: Int? = nil) -> [String: Any] {
    ["rowHeight": 60.0, "items": ids.map { id -> [String: Any] in
      ["id": id, "value": value, "semanticLabel": "Switch \(id)", "tintColor": tint.map { $0 as Any } ?? NSNull()]
    }]
  }

  func testSwitchGroupValidationRejectsInvalidReleaseArguments() {
    XCTAssertNotNil(AppleLiquidSwitchGroupConfiguration(arguments: switchGroupArguments(["a", "b"])))
    for height in [43.0, Double.infinity, Double.nan] {
      var args = switchGroupArguments(["a"])
      args["rowHeight"] = height
      XCTAssertNil(AppleLiquidSwitchGroupConfiguration(arguments: args))
    }
    XCTAssertNil(AppleLiquidSwitchGroupConfiguration(arguments: switchGroupArguments(["a", "a"])))
    XCTAssertNil(AppleLiquidSwitchGroupConfiguration(arguments: switchGroupArguments([""])))
    var args = switchGroupArguments(["a"])
    args["items"] = [["id": "a", "value": 1, "semanticLabel": "a"]]
    XCTAssertNil(AppleLiquidSwitchGroupConfiguration(arguments: args))
  }

  func testSwitchGroupRetainsControlsAcrossReorderAndDefersActiveValueAndTint() throws {
    let messenger = SwitchGroupTestMessenger()
    let platform = AppleLiquidSwitchGroupPlatformView(frame: CGRect(x: 0, y: 0, width: 76, height: 120),
      viewIdentifier: 7, arguments: switchGroupArguments(["a", "b"]), messenger: messenger)
    let initial = platform.view().subviews.compactMap { $0 as? UISwitch }
    let first = try XCTUnwrap(initial.first)
    let second = try XCTUnwrap(initial.last)
    let originalTint = first.onTintColor
    first.sendActions(for: .touchDown)
    messenger.update(switchGroupArguments(["b", "a"], value: true, tint: 0xFFFF0000))
    XCTAssertFalse(first.isOn)
    XCTAssertEqual(first.onTintColor, originalTint)
    XCTAssertTrue(second.isOn)
    second.sendActions(for: .valueChanged)
    XCTAssertEqual(messenger.events.last?.method, "valueChanged")
    XCTAssertEqual((messenger.events.last?.arguments as? [String: Any])?["id"] as? String, "b")
    platform.view().layoutIfNeeded()
    XCTAssertGreaterThan(first.center.y, second.center.y)
    XCTAssertEqual(first.accessibilityLabel, "Switch a")
    XCTAssertTrue(platform.view().subviews.contains { $0 === first })
    first.sendActions(for: .touchUpInside)
    let reconciled = expectation(description: "Active control reconciles latest configuration")
    DispatchQueue.main.async { reconciled.fulfill() }
    wait(for: [reconciled], timeout: 1)
    XCTAssertTrue(first.isOn)
    XCTAssertEqual(first.onTintColor, UIColor(appleLiquidARGB: 0xFFFF0000))
    messenger.update(switchGroupArguments(["b"]))
    XCTAssertNil(first.superview)
    XCTAssertTrue(platform.view().subviews.first === second)
    let count = messenger.events.count
    first.sendActions(for: .valueChanged)
    XCTAssertEqual(messenger.events.count, count)
  }

  func testSwitchGroupDoesNotResetUserValueBeforeFlutterAcknowledges() throws {
    let messenger = SwitchGroupTestMessenger()
    let platform = AppleLiquidSwitchGroupPlatformView(
      frame: CGRect(x: 0, y: 0, width: 76, height: 60),
      viewIdentifier: 8, arguments: switchGroupArguments(["a"]), messenger: messenger)
    let control = try XCTUnwrap(platform.view().subviews.compactMap { $0 as? UISwitch }.first)
    control.sendActions(for: .touchDown)
    control.setOn(true, animated: false)
    control.sendActions(for: .valueChanged)
    control.sendActions(for: .touchUpInside)
    let ended = expectation(description: "Interaction-end reconciliation has run")
    DispatchQueue.main.async { ended.fulfill() }
    wait(for: [ended], timeout: 1)
    XCTAssertTrue(control.isOn, "An unchanged cached configuration must not undo the user toggle")
    let valueEvent = try XCTUnwrap(messenger.events.first { $0.method == "valueChanged" })
    XCTAssertEqual((valueEvent.arguments as? [String: Any])?["value"] as? Bool, true)

    messenger.update(switchGroupArguments(["a"], value: false))
    XCTAssertFalse(control.isOn, "An explicit Flutter acknowledgement remains authoritative")
  }

  func testSwitchGroupTintOnlyUpdatePreservesUserValueUntilFlutterAcknowledges() throws {
    for initialValue in [false, true] {
      let initialTint: Int? = initialValue ? 0xFF0000FF : nil
      let updatedTint: Int? = initialValue ? nil : 0xFFFF0000
      let messenger = SwitchGroupTestMessenger()
      let platform = AppleLiquidSwitchGroupPlatformView(
        frame: CGRect(x: 0, y: 0, width: 76, height: 60),
        viewIdentifier: 9,
        arguments: switchGroupArguments(["a"], value: initialValue, tint: initialTint),
        messenger: messenger)
      let control = try XCTUnwrap(platform.view().subviews.compactMap { $0 as? UISwitch }.first)
      let originalTint = control.onTintColor

      control.sendActions(for: .touchDown)
      messenger.update(switchGroupArguments(["a"], value: initialValue, tint: updatedTint))
      XCTAssertEqual(control.onTintColor, originalTint, "Tint stays deferred during the gesture")
      control.setOn(!initialValue, animated: false)
      control.sendActions(for: .valueChanged)
      control.sendActions(for: .touchUpInside)
      let ended = expectation(description: "Tint-only reconciliation has run")
      DispatchQueue.main.async { ended.fulfill() }
      wait(for: [ended], timeout: 1)

      XCTAssertEqual(control.isOn, !initialValue, "Tint must not replay the old Boolean")
      XCTAssertEqual(control.onTintColor, UIColor(appleLiquidARGB: updatedTint))
      let valueEvent = try XCTUnwrap(messenger.events.first { $0.method == "valueChanged" })
      XCTAssertEqual((valueEvent.arguments as? [String: Any])?["value"] as? Bool, !initialValue)

      messenger.update(switchGroupArguments(["a"], value: initialValue, tint: updatedTint))
      XCTAssertEqual(control.isOn, initialValue, "An explicit Flutter rejection still takes effect")
    }
  }

  func testSwitchGroupValueOnlyUpdateStillReconcilesAfterInteraction() throws {
    let messenger = SwitchGroupTestMessenger()
    let platform = AppleLiquidSwitchGroupPlatformView(
      frame: CGRect(x: 0, y: 0, width: 76, height: 60),
      viewIdentifier: 10,
      arguments: switchGroupArguments(["a"], tint: 0xFF0000FF), messenger: messenger)
    let control = try XCTUnwrap(platform.view().subviews.compactMap { $0 as? UISwitch }.first)
    let originalTint = control.onTintColor
    control.sendActions(for: .touchDown)
    messenger.update(switchGroupArguments(["a"], value: true, tint: 0xFF0000FF))
    XCTAssertFalse(control.isOn, "Value stays deferred during the gesture")
    control.sendActions(for: .touchUpInside)
    let ended = expectation(description: "Value-only reconciliation has run")
    DispatchQueue.main.async { ended.fulfill() }
    wait(for: [ended], timeout: 1)
    XCTAssertTrue(control.isOn, "A genuine deferred value change must still be applied")
    XCTAssertEqual(control.onTintColor, originalTint)
  }

  @available(iOS 16.0, *)
  private func visibilityToast(
    _ id: String,
    duration: Any = NSNull(),
    maxVisibleToasts: Any = NSNull(),
    dismissesOnAction: Bool = true
  ) throws -> AppleLiquidToastConfiguration {
    try XCTUnwrap(AppleLiquidToastConfiguration(arguments: [
      "id": id,
      "title": id,
      "duration": duration,
      "maxVisibleToasts": maxVisibleToasts,
      "actionTitle": "Open",
      "actionId": "\(id)_action",
      "dismissesOnAction": dismissesOnAction,
    ]))
  }

  @available(iOS 16.0, *)
  func testToastVisibilityOnShowAndLastSwipeDismissal() throws {
    var changes: [Bool] = []
    let model = AppleLiquidToastModel(onStackVisibilityChanged: {
      changes.append($0)
    }) { _ in }
    XCTAssertFalse(model.isStackVisible)
    XCTAssertTrue(changes.isEmpty)
    model.show(try visibilityToast("first"))
    XCTAssertTrue(model.isStackVisible)
    model.dismiss(id: "first") // Same synchronous removal as the swipe handler.
    XCTAssertFalse(model.isStackVisible)
    XCTAssertEqual(changes, [true, false])
  }

  @available(iOS 16.0, *)
  func testToastVisibilityWhenOnlyOneOfSeveralToastsIsDismissed() throws {
    var changes: [Bool] = []
    let model = AppleLiquidToastModel(onStackVisibilityChanged: {
      changes.append($0)
    }) { _ in }
    model.show(try visibilityToast("first"))
    model.show(try visibilityToast("second"))
    model.dismiss(id: "first")
    XCTAssertTrue(model.isStackVisible)
    XCTAssertEqual(changes, [true])
    model.dismiss(id: "second")
    XCTAssertEqual(changes, [true, false])
  }

  @available(iOS 16.0, *)
  func testToastVisibilityOnAutomaticExpiry() throws {
    let expired = expectation(description: "Last toast expires natively")
    var changes: [Bool] = []
    var dismissedIDs: [String] = []
    let model = AppleLiquidToastModel(onStackVisibilityChanged: { visible in
      changes.append(visible)
      if !visible { expired.fulfill() }
    }) { dismissedIDs.append($0) }
    model.show(try visibilityToast("expiring", duration: 1.0))
    wait(for: [expired], timeout: 3)
    XCTAssertFalse(model.isStackVisible)
    XCTAssertEqual(changes, [true, false])
    XCTAssertEqual(dismissedIDs, ["expiring"])
  }

  @available(iOS 16.0, *)
  func testToastVisibilityOnClosingActionAndDismissAll() throws {
    var changes: [Bool] = []
    let model = AppleLiquidToastModel(onStackVisibilityChanged: {
      changes.append($0)
    }) { _ in }
    let closing = try visibilityToast("closing")
    model.show(closing)
    if closing.dismissesOnAction { model.dismiss(id: closing.id) }
    XCTAssertEqual(changes, [true, false])

    let persistent = try visibilityToast("persistent", dismissesOnAction: false)
    model.show(persistent)
    if persistent.dismissesOnAction { model.dismiss(id: persistent.id) }
    XCTAssertTrue(model.isStackVisible)
    model.show(try visibilityToast("second"))
    model.dismiss()
    model.dismiss()
    XCTAssertFalse(model.isStackVisible)
    XCTAssertEqual(changes, [true, false, true, false])
  }

  @available(iOS 16.0, *)
  func testHiddenExpiredToastDoesNotReappear() throws {
    let expired = expectation(description: "Hidden toast expires natively")
    var changes: [Bool] = []
    let model = AppleLiquidToastModel(onStackVisibilityChanged: {
      changes.append($0)
    }) { _ in expired.fulfill() }
    model.show(try visibilityToast("expiring", duration: 1.0))
    model.setVisible(false)
    wait(for: [expired], timeout: 3)
    model.setVisible(true)
    XCTAssertTrue(model.activeToasts.isEmpty)
    XCTAssertFalse(model.isStackVisible)
    XCTAssertEqual(changes, [true, false])
  }

  @available(iOS 16.0, *)
  func testToastVisibilityOnHideRestoreAndSheetSuspension() throws {
    var changes: [Bool] = []
    let model = AppleLiquidToastModel(onStackVisibilityChanged: {
      changes.append($0)
    }) { _ in }
    model.setVisible(false)
    model.show(try visibilityToast("hidden"))
    XCTAssertFalse(model.isStackVisible)
    XCTAssertTrue(changes.isEmpty)
    model.setVisible(true)
    model.setVisible(true)
    model.setSheetPresented(true)
    model.setVisible(false)
    model.setSheetPresented(false)
    XCTAssertFalse(model.isStackVisible)
    model.setVisible(true)
    XCTAssertEqual(changes, [true, false, true])
    model.setSheetPresented(true)
    model.setVisible(true)
    XCTAssertFalse(model.isStackVisible)
    model.setSheetPresented(false)
    XCTAssertTrue(model.isStackVisible)
    model.dismiss()
    model.setVisible(false)
    model.setVisible(true)
    XCTAssertFalse(model.isStackVisible)
    XCTAssertEqual(changes, [true, false, true, false, true, false])
  }

  @available(iOS 16.0, *)
  func testToastVisibilityStaysTrueWhenThirdToastBecomesSummary() throws {
    var changes: [Bool] = []
    var dismissedIDs: [String] = []
    let model = AppleLiquidToastModel(onStackVisibilityChanged: {
      changes.append($0)
    }) { dismissedIDs.append($0) }
    for index in 1...3 {
      model.show(try visibilityToast("toast_\(index)", maxVisibleToasts: 2))
    }
    let summary = try XCTUnwrap(model.activeToasts.first)
    XCTAssertTrue(summary.isOverflowSummary)
    XCTAssertEqual(model.activeToasts.count, 1)
    XCTAssertEqual(dismissedIDs, ["toast_1", "toast_2", "toast_3"])
    XCTAssertEqual(changes, [true])
    model.show(try visibilityToast("fourth", maxVisibleToasts: 2))
    model.show(try visibilityToast("unlimited"))
    XCTAssertEqual(changes, [true])
    model.dismiss(id: "unlimited")
    XCTAssertEqual(changes, [true, false])
  }

  @available(iOS 16.0, *)
  private func toastOverlayWindow() throws -> AppleLiquidToastOverlayWindow {
    let scene = try XCTUnwrap(
      UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    )
    return AppleLiquidToastOverlayWindow(windowScene: scene)
  }

  @available(iOS 16.0, *)
  func testToastOverlayRetainsHitFrameWhenSummaryUpdates() throws {
    let window = try toastOverlayWindow()
    let model = AppleLiquidToastModel { _ in }
    for id in ["first", "second", "third"] {
      model.show(try visibilityToast(id, maxVisibleToasts: 2))
    }
    let summaryID = try XCTUnwrap(model.activeToasts.first?.id)
    window.updateLayout(for: model.activeToasts)
    window.updateHitFrame(AppleLiquidToastHitFrame(
      id: summaryID,
      geometryFrame: CGRect(x: 15, y: 20, width: 300, height: 50),
      placementOffset: -60
    ))
    let point = CGPoint(x: 100, y: 100)
    XCTAssertFalse(window.canBecomeKey)
    XCTAssertTrue(window.point(inside: point, with: nil))
    XCTAssertFalse(window.point(inside: CGPoint(x: 0, y: 100), with: nil))
    for id in ["fourth", "fifth"] {
      model.show(try visibilityToast(id, maxVisibleToasts: 2))
      XCTAssertEqual(model.activeToasts.first?.id, summaryID)
      // The direct show path and Combine sink both update the same layout.
      window.updateLayout(for: model.activeToasts)
      XCTAssertTrue(window.point(inside: point, with: nil), id)
      window.updateLayout(for: model.activeToasts)
      XCTAssertTrue(window.point(inside: point, with: nil), "repeated \(id)")
    }
    window.updateLayout(for: [])
    XCTAssertFalse(window.point(inside: point, with: nil))
  }

  @available(iOS 16.0, *)
  func testToastOverlayRemovesStaleIDsAndHiddenHitFrames() throws {
    let window = try toastOverlayWindow()
    let first = try visibilityToast("first")
    let second = try visibilityToast("second")
    let third = try visibilityToast("third")
    window.updateLayout(for: [first, second])
    for (id, y) in [(first.id, 20.0), (second.id, 100.0)] {
      window.updateHitFrame(AppleLiquidToastHitFrame(
        id: id, geometryFrame: CGRect(x: 15, y: y, width: 300, height: 50),
        placementOffset: 0
      ))
    }
    let firstPoint = CGPoint(x: 100, y: 45)
    let secondPoint = CGPoint(x: 100, y: 125)
    XCTAssertTrue(window.point(inside: firstPoint, with: nil))
    XCTAssertTrue(window.point(inside: secondPoint, with: nil))
    window.updateLayout(for: [second, third])
    XCTAssertFalse(window.point(inside: firstPoint, with: nil))
    XCTAssertTrue(window.point(inside: secondPoint, with: nil))
    window.removeHitFrame(id: second.id)
    XCTAssertFalse(window.point(inside: secondPoint, with: nil))
    window.updateHitFrame(AppleLiquidToastHitFrame(
      id: third.id, geometryFrame: CGRect(x: 15, y: 100, width: 300, height: 50),
      placementOffset: 0
    ))
    window.updateLayout(for: []) // Same path as hide, sheet suspension and dismiss.
    XCTAssertFalse(window.point(inside: secondPoint, with: nil))
    window.updateLayout(for: [second, third])
    XCTAssertFalse(window.point(inside: secondPoint, with: nil))
  }

  @available(iOS 16.0, *)
  func testToastOverlayInvalidatesHitFramesWhenWindowGeometryChanges() throws {
    let window = try toastOverlayWindow()
    let toast = try visibilityToast("first")
    let hitFrame = AppleLiquidToastHitFrame(
      id: toast.id, geometryFrame: CGRect(x: 15, y: 20, width: 300, height: 50),
      placementOffset: -60
    )
    let point = CGPoint(x: 100, y: 100)
    window.updateLayout(for: [toast])
    window.updateHitFrame(hitFrame)
    XCTAssertTrue(window.point(inside: point, with: nil))
    window.frame = window.frame.insetBy(dx: 10, dy: 0)
    window.updateLayout(for: [toast])
    XCTAssertFalse(window.point(inside: point, with: nil))
    window.updateHitFrame(hitFrame)
    XCTAssertTrue(window.point(inside: point, with: nil))
    let offsetToast = try XCTUnwrap(AppleLiquidToastConfiguration(arguments: [
      "id": toast.id, "title": "Moved", "placementOffset": -140.0,
      "duration": NSNull(),
    ]))
    window.updateLayout(for: [offsetToast])
    XCTAssertFalse(window.point(inside: point, with: nil))
  }

  @available(iOS 16.0, *)
  func testToastHitFrameUsesWindowCoordinates() {
    let frame = AppleLiquidToastHitFrame(
      id: "action-toast",
      geometryFrame: CGRect(x: 15, y: 20, width: 410, height: 50),
      placementOffset: -60
    )

    XCTAssertEqual(
      frame.rect,
      CGRect(x: 15, y: 80, width: 410, height: 50)
    )
  }

  @available(iOS 16.0, *)
  func testToastOverflowRetainsOnlyTheCurrentSummaryAction() throws {
    var dismissedIDs: [String] = []
    let model = AppleLiquidToastModel { dismissedIDs.append($0) }

    func toast(
      _ id: String,
      limited: Bool = true
    ) throws -> AppleLiquidToastConfiguration {
      try XCTUnwrap(AppleLiquidToastConfiguration(arguments: [
        "id": id,
        "title": id,
        "duration": NSNull(),
        "maxVisibleToasts": limited ? 2 as Any : NSNull(),
        "overflowTitle": "{count} notifications",
        "actionTitle": "Individual",
        "actionId": "\(id)_individual_action",
        "isWholeToastTappable": true,
        "overflowAction": [
          "toastId": "\(id)_overflow",
          "title": "Open",
          "actionId": "\(id)_summary_action",
          "tintColor": 0xFFFF9500,
          "dismissesToast": false,
        ],
      ]))
    }

    model.show(try toast("first"))
    model.show(try toast("second"))
    model.show(try toast("third"))

    let summary = try XCTUnwrap(model.activeToasts.first)
    XCTAssertEqual(model.activeToasts.count, 1)
    XCTAssertEqual(summary.title, "3 notifications")
    XCTAssertTrue(summary.isOverflowSummary)
    XCTAssertEqual(summary.actionTitle, "Open")
    XCTAssertEqual(summary.actionId, "third_summary_action")
    XCTAssertEqual(
      summary.actionTintColor,
      Color(.sRGB, red: 1, green: 149.0 / 255.0, blue: 0, opacity: 1)
    )
    XCTAssertFalse(summary.dismissesOnAction)
    XCTAssertFalse(summary.isWholeToastTappable)
    XCTAssertEqual(summary.callbackToastIDs, ["third_overflow"])
    XCTAssertEqual(dismissedIDs, [
      "first", "first_overflow", "second", "second_overflow", "third",
    ])

    model.show(try toast("fourth"))
    let updatedSummary = try XCTUnwrap(model.activeToasts.first)
    XCTAssertEqual(updatedSummary.id, summary.id)
    XCTAssertEqual(updatedSummary.title, "4 notifications")
    XCTAssertEqual(updatedSummary.actionId, "fourth_summary_action")
    XCTAssertEqual(Array(dismissedIDs.suffix(2)), ["third_overflow", "fourth"])

    model.show(try toast("unlimited", limited: false))
    XCTAssertEqual(dismissedIDs.last, "fourth_overflow")
    XCTAssertFalse(try XCTUnwrap(model.activeToasts.first).isOverflowSummary)
    model.dismiss()
    XCTAssertTrue(model.activeToasts.isEmpty)
    XCTAssertEqual(Array(dismissedIDs.suffix(2)), ["unlimited", "unlimited_overflow"])
  }

  @available(iOS 16.0, *)
  func testToastOverflowWithoutActionKeepsCountOnlySummary() throws {
    let model = AppleLiquidToastModel { _ in }
    for index in 1...3 {
      model.show(try XCTUnwrap(AppleLiquidToastConfiguration(arguments: [
        "id": "toast_\(index)",
        "title": "Toast \(index)",
        "duration": NSNull(),
        "maxVisibleToasts": 2,
        "overflowTitle": "{count} notifications",
      ])))
    }
    let summary = try XCTUnwrap(model.activeToasts.first)
    XCTAssertEqual(summary.title, "3 notifications")
    XCTAssertNil(summary.actionTitle)
    XCTAssertNil(summary.actionId)
    XCTAssertEqual(summary.callbackToastIDs, [summary.id])
    model.dismiss()
  }

  func testConcentricRectangleConfigurationResolvesFallbackRadii() {
    let configuration = AppleConcentricRectangleConfiguration(arguments: [
      "inset": 8.0,
      "containerCornerRadius": 40.0,
      "corners": [
        "grouping": "topAndBottom",
        "topLeading": ["kind": "fixed", "radius": 12.0],
        "topTrailing": ["kind": "fixed", "radius": 24.0],
        "bottomLeading": [
          "kind": "concentric", "minimumRadius": 10.0,
        ],
        "bottomTrailing": ["kind": "fixed", "radius": 18.0],
      ],
    ])

    XCTAssertEqual(configuration.grouping, .topAndBottom)
    XCTAssertEqual(
      configuration.fallbackRadii,
      AppleConcentricRectangleRadii(
        topLeading: 24,
        topTrailing: 24,
        bottomLeading: 32,
        bottomTrailing: 32
      )
    )
  }

  func testConcentricRectangleConfigurationSanitizesInvalidNumbers() {
    let configuration = AppleConcentricRectangleConfiguration(arguments: [
      "inset": Double.nan,
      "containerCornerRadius": -1.0,
      "corners": [
        "topLeading": ["kind": "fixed", "radius": Double.infinity]
      ],
    ])

    XCTAssertEqual(configuration.inset, 0)
    XCTAssertNil(configuration.containerCornerRadius)
    XCTAssertEqual(configuration.fallbackRadii.topLeading, 0)
  }

  func testSliderConfigurationRejectsMalformedRanges() {
    XCTAssertNil(
      AppleLiquidSliderConfiguration(
        arguments: ["min": 1.0, "max": 0.0, "value": 0.5]
      )
    )
    XCTAssertNil(
      AppleLiquidSliderConfiguration(
        arguments: ["min": Double.nan, "max": 1.0, "value": 0.5]
      )
    )

    let configuration = AppleLiquidSliderConfiguration(
      arguments: ["min": 0.0, "max": 1.0, "value": 0.5, "step": 0.25]
    )
    XCTAssertEqual(configuration?.min, 0)
    XCTAssertEqual(configuration?.max, 1)
    XCTAssertEqual(configuration?.step, 0.25)
  }

  @MainActor
  func testNativeSliderValueChangesPreserveConfiguredSteps() throws {
    for step: Double? in [nil, 0.1, 0.25] {
      var arguments: [String: Any] = ["value": 0.5, "min": 0.0, "max": 1.0]
      if let step { arguments["step"] = step }
      let configuration = try XCTUnwrap(
        AppleLiquidSliderConfiguration(arguments: arguments)
      )
      let model = AppleLiquidSliderModel(configuration: configuration)
      var changes: [Double] = []
      model.onValueChanged = { changes.append($0) }
      let host = UIHostingController(rootView: AppleLiquidSliderView(model: model))
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 100))
      window.rootViewController = host
      window.makeKeyAndVisible()
      host.view.layoutIfNeeded()
      RunLoop.main.run(until: Date().addingTimeInterval(0.1))
      defer { window.isHidden = true }

      let slider = try XCTUnwrap(firstSubview(of: UISlider.self, in: host.view))
      for fraction: Float in [0.25, 0.75] {
        slider.value = slider.minimumValue +
          fraction * (slider.maximumValue - slider.minimumValue)
        slider.sendActions(for: .valueChanged)
        let expected = step.map { (Double(fraction) / $0).rounded() * $0 } ??
          Double(fraction)
        XCTAssertEqual(model.value, expected, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(changes.last), expected, accuracy: 0.0001)
      }
    }
  }

  func testSymbolConfigurationBoundsNativeRasterization() {
    XCTAssertNil(
      AppleLiquidSymbolConfiguration(arguments: ["size": 513.0])
    )
    XCTAssertNil(
      AppleLiquidSymbolConfiguration(arguments: ["size": 512.0, "scale": 4.1])
    )

    let configuration = AppleLiquidSymbolConfiguration(
      arguments: ["size": 256.0, "scale": 4.0]
    )
    XCTAssertEqual(configuration?.pointSize, 256)
    XCTAssertEqual(configuration?.scale, 4)
  }

  func testDetentConfigurationDefaultsForMissingOrMalformedInput() {
    let values: [Any?] = [nil, NSNull(), "invalid", 42, [String: Any]()]
    for value in values {
      let configuration = AppleLiquidSheetDetentConfiguration(value: value)
      XCTAssertNil(configuration.initialHeight)
      XCTAssertNil(configuration.expandedHeight)
      XCTAssertTrue(configuration.allowsAutomaticExpansion)
    }
    XCTAssertNil(AppleLiquidSheetDetentConfiguration.automatic.initialHeight)
    XCTAssertNil(AppleLiquidSheetDetentConfiguration.automatic.expandedHeight)
    XCTAssertTrue(AppleLiquidSheetDetentConfiguration.automatic.allowsAutomaticExpansion)

    let invalidHeights: [Any] = [NSNull(), "420", 0, -1.0]
    for height in invalidHeights {
      let configuration = AppleLiquidSheetDetentConfiguration(value: [
        "initialHeight": height,
        "expandedHeight": height,
        "allowsAutomaticExpansion": NSNull(),
      ])
      XCTAssertNil(configuration.initialHeight)
      XCTAssertNil(configuration.expandedHeight)
      XCTAssertTrue(configuration.allowsAutomaticExpansion)
    }
  }

  func testDetentConfigurationPreservesNumericHeights() {
    let cases: [(Any, CGFloat)] = [(420.5, 420.5), (NSNumber(value: 300), 300)]
    for (height, expected) in cases {
      let configuration = AppleLiquidSheetDetentConfiguration(value: [
        "initialHeight": height,
        "expandedHeight": NSNumber(value: 640.25),
        "allowsAutomaticExpansion": false,
      ])
      XCTAssertEqual(configuration.initialHeight, expected)
      XCTAssertEqual(configuration.expandedHeight, 640.25)
      XCTAssertFalse(configuration.allowsAutomaticExpansion)
    }
  }

  func testDetentConfigurationPreservesExpansionConversion() {
    let cases: [(Any, Bool)] = [
      (true, true), (false, false),
      (NSNumber(value: 1), true), (NSNumber(value: 0), false),
      (NSNumber(value: 2), true), ("false", true), (NSNull(), true),
    ]
    for (value, expected) in cases {
      let configuration = AppleLiquidSheetDetentConfiguration(value: [
        "allowsAutomaticExpansion": value,
      ])
      XCTAssertEqual(configuration.allowsAutomaticExpansion, expected)
    }
  }

  func testAvatarURLPolicyNormalizesAndRejectsInvalidHosts() {
    XCTAssertEqual(
      AppleLiquidAvatarURLPolicy.allowedHosts([
        " Images.Example.COM\n", "images.example.com", "cdn-1.example.com",
        "", "bad_host.example.com", "-bad.example.com", "bad-.example.com",
        "images.example.com.", "127.0.0.1", "999.999.999.999", 42, NSNull(),
      ] as [Any]),
      Set(["images.example.com", "cdn-1.example.com"])
    )
    XCTAssertTrue(AppleLiquidAvatarURLPolicy.allowedHosts(nil).isEmpty)
    XCTAssertTrue(AppleLiquidAvatarURLPolicy.allowedHosts("images.example.com").isEmpty)
  }

  func testAvatarURLPolicyPreservesOptionalURLAndCredentialRules() throws {
    let hosts: Set<String> = ["images.example.com"]
    for value in [nil, NSNull(), 42, "", " \n", "not a URL"] as [Any?] {
      XCTAssertNil(AppleLiquidAvatarURLPolicy.optionalURL(value, allowedHosts: hosts))
    }
    for value in [
      "HTTPS://IMAGES.EXAMPLE.COM:443/avatar.png?size=2#avatar",
      "https://images.example.com/avatar.png",
    ] {
      XCTAssertEqual(
        AppleLiquidAvatarURLPolicy.optionalURL(value, allowedHosts: hosts),
        try XCTUnwrap(URL(string: value))
      )
    }
    for value in [
      "https://user@images.example.com/avatar.png",
      "https://user:secret@images.example.com/avatar.png",
      "https://sub.images.example.com/avatar.png",
      "https://images.example.com.evil.example/avatar.png",
      "https://127.0.0.1/avatar.png",
      "http://images.example.com/avatar.png",
      "https://images.example.com:8443/avatar.png",
    ] {
      XCTAssertNil(AppleLiquidAvatarURLPolicy.optionalURL(value, allowedHosts: hosts), value)
    }
    XCTAssertNil(AppleLiquidAvatarURLPolicy.optionalURL(
      "https://images.example.com/avatar.png", allowedHosts: []
    ))
  }

  func testAvatarURLPolicyRequiresExactHTTPSHostAllowlist() throws {
    let allowedHosts = AppleLiquidAvatarURLPolicy.allowedHosts(
      ["images.example.com"] as [Any]
    )
    let allowedURL = try XCTUnwrap(
      URL(string: "https://images.example.com/avatar.png")
    )
    let httpURL = try XCTUnwrap(
      URL(string: "http://images.example.com/avatar.png")
    )
    let otherHostURL = try XCTUnwrap(
      URL(string: "https://cdn.example.com/avatar.png")
    )
    let portURL = try XCTUnwrap(
      URL(string: "https://images.example.com:8443/avatar.png")
    )

    XCTAssertTrue(
      AppleLiquidAvatarURLPolicy.allows(
        allowedURL,
        allowedHosts: allowedHosts
      )
    )
    XCTAssertFalse(
      AppleLiquidAvatarURLPolicy.allows(httpURL, allowedHosts: allowedHosts)
    )
    XCTAssertFalse(
      AppleLiquidAvatarURLPolicy.allows(
        otherHostURL,
        allowedHosts: allowedHosts
      )
    )
    XCTAssertFalse(
      AppleLiquidAvatarURLPolicy.allows(portURL, allowedHosts: allowedHosts)
    )
  }

  func testPluginCanBeCreated() {
    let plugin = AppleLiquidTabbarPlugin()
    XCTAssertNotNil(plugin)
  }

  @MainActor
  func testTabBadgeSynchronizationSkipsUnchangedWritesAndRepairsNativeState() throws {
    func items(_ color: Int, _ value: String) -> [AppleLiquidTabbarItem] {
      AppleLiquidTabbarConfiguration(arguments: [
        "items": [["title": "Slider", "systemImage": "slider.horizontal.3",
          "notificationDotColor": color, "notificationBadgeValue": value]],
      ]).items
    }
    let bar = BadgeWriteCountingTabBar()
    let item = BadgeWriteCountingTabBarItem(title: "Slider", image: nil, tag: 0)
    bar.items = [item]
    let standard = UITabBarAppearance()
    standard.backgroundColor = .green
    bar.standardAppearance = standard
    if #available(iOS 15.0, *) {
      let edge = UITabBarAppearance()
      edge.backgroundColor = .yellow
      bar.scrollEdgeAppearance = edge
    }
    let blue = 0xFF007AFF
    let red = 0xFFFF0000
    bar.appleLiquidApplyNotificationDots(from: items(blue, "3"))
    let appearanceWrites = bar.appearanceWrites
    let itemWrites = item.badgeWrites
    for _ in 0..<10 { bar.appleLiquidApplyNotificationDots(from: items(blue, "3")) }
    XCTAssertEqual(bar.appearanceWrites, appearanceWrites)
    XCTAssertEqual(item.badgeWrites, itemWrites)

    bar.appleLiquidApplyNotificationDots(from: items(red, "7"))
    XCTAssertEqual(item.badgeValue, "7")
    XCTAssertEqual(item.badgeColor, UIColor(appleLiquidARGB: red))
    XCTAssertEqual(bar.standardAppearance.backgroundColor, .green)
    var appearances = [bar.standardAppearance]
    if #available(iOS 15.0, *) {
      let edge = try XCTUnwrap(bar.scrollEdgeAppearance)
      XCTAssertEqual(edge.backgroundColor, .yellow)
      appearances.append(edge)
    }
    for appearance in appearances {
      for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance,
        appearance.compactInlineLayoutAppearance] {
        XCTAssertEqual(layout.normal.badgeBackgroundColor, UIColor(appleLiquidARGB: red))
        XCTAssertEqual(layout.selected.badgeBackgroundColor, UIColor(appleLiquidARGB: red))
      }
    }

    let replacement = BadgeWriteCountingTabBarItem(title: "Slider", image: nil, tag: 0)
    bar.items = [replacement]
    bar.appleLiquidApplyNotificationDots(from: items(red, "7"))
    XCTAssertEqual(replacement.badgeValue, "7")
    XCTAssertEqual(replacement.badgeColor, UIColor(appleLiquidARGB: red))
    replacement.badgeValue = nil
    replacement.badgeColor = nil
    replacement.setBadgeTextAttributes([.foregroundColor: UIColor.clear], for: .normal)
    let reset = bar.standardAppearance.copy()
    reset.inlineLayoutAppearance.selected.badgeBackgroundColor = .black
    bar.standardAppearance = reset
    bar.appleLiquidApplyNotificationDots(from: items(red, "7"))
    XCTAssertEqual(replacement.badgeValue, "7")
    XCTAssertEqual(replacement.badgeColor, UIColor(appleLiquidARGB: red))
    XCTAssertEqual(replacement.badgeTextAttributes(for: .normal)?[.foregroundColor] as? UIColor, .white)
    XCTAssertEqual(bar.standardAppearance.inlineLayoutAppearance.selected.badgeBackgroundColor,
      UIColor(appleLiquidARGB: red))
  }

  func testTabSelectionDoesNotPublishUnchangedClampedIndex() {
    let model = AppleLiquidTabbarModel(configuration: AppleLiquidTabbarConfiguration(arguments: [
      "items": [["title": "Home", "systemImage": "house"]],
    ]))
    var publications = 0
    var selections: [Int] = []
    let observation = model.$selectedIndex.dropFirst().sink { _ in publications += 1 }
    defer { observation.cancel() }
    model.onSelectionChanged = { selections.append($0) }
    model.setSelectedIndex(-1, notifyFlutter: true)
    model.setSelectedIndex(0, notifyFlutter: false)
    XCTAssertEqual(publications, 0)
    model.setSelectedIndex(99, notifyFlutter: true)
    XCTAssertEqual(publications, 1)
    XCTAssertEqual(selections, [1])
    model.setSelectedIndex(1, notifyFlutter: false)
    XCTAssertEqual(publications, 1)
    model.setSelectedIndex(0, notifyFlutter: false)
    XCTAssertEqual(publications, 2)
    XCTAssertEqual(selections, [1])
  }

  @MainActor
  func testTrailingTabUsesNativeProminentRoleWithSearchFallback() throws {
    guard #available(iOS 18.0, *) else {
      throw XCTSkip("SwiftUI tabs require iOS 18 or newer.")
    }

    let configuration = AppleLiquidTabbarConfiguration(arguments: [
      "items": [
        ["title": "Overview", "systemImage": "house.fill"],
        ["title": "Journal", "systemImage": "book.closed.fill"],
        ["title": "Fitness", "systemImage": "figure.run"],
      ],
      "searchItem": ["title": "Add", "systemImage": "plus"],
    ])
    let model = AppleLiquidTabbarModel(configuration: configuration)
    let host = AppleLiquidTabbarHostingController(
      rootView: AppleLiquidSwiftUITabView(model: model),
      model: model
    )
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))
    defer { window.isHidden = true }

    func tabController(in controller: UIViewController) -> UITabBarController? {
      if let tabController = controller as? UITabBarController {
        return tabController
      }
      return controller.children.lazy.compactMap { tabController(in: $0) }.first
    }

    let controller = try XCTUnwrap(tabController(in: host))
    let items = try XCTUnwrap(controller.tabBar.items)
    XCTAssertEqual(items.count, 4)

    #if compiler(>=6.4)
    if #available(iOS 27.0, *) {
      XCTAssertEqual(controller.tabs.count, 4)
      let trailingTab = try XCTUnwrap(controller.tabs.last)
      XCTAssertEqual(controller.prominentTabIdentifier, trailingTab.identifier)
      XCTAssertFalse(trailingTab is UISearchTab)
      return
    }
    #endif

    // iOS 26 SwiftUI uses viewControllers instead of populating UIKit tabs.
    let trailingItem = try XCTUnwrap(items.last)
    XCTAssertEqual(
      trailingItem.title,
      UISearchTab(viewControllerProvider: nil).title
    )
  }

  func testTabBarCompactionKeepsSelectedRegularTabAndSearchAction() {
    let configuration = AppleLiquidTabbarConfiguration(arguments: [
      "currentIndex": 2,
      "items": [
        ["title": "Overview", "systemImage": "house.fill"],
        ["title": "Journal", "systemImage": "book.closed.fill"],
        ["title": "Fitness", "systemImage": "figure.run"],
      ],
      "searchItem": [
        "title": "Add", "systemImage": "plus", "isSearch": true,
      ],
    ])
    let model = AppleLiquidTabbarModel(configuration: configuration)

    XCTAssertEqual(model.displayedRegularIndices, [0, 1, 2])
    XCTAssertEqual(
      model.displayedItems.map(\.title),
      ["Overview", "Journal", "Fitness", "Add"]
    )

    model.setMinimized(true)

    XCTAssertTrue(model.isCompressing)
    XCTAssertFalse(model.isMinimized)

    model.setMinimized(true, animated: false)

    XCTAssertFalse(model.isCompressing)
    XCTAssertTrue(model.isMinimized)
    XCTAssertEqual(model.displayedRegularIndices, [2])
    XCTAssertEqual(model.displayedItems.map(\.title), ["Fitness", "Add"])

    model.setMinimized(false)

    XCTAssertEqual(model.displayedRegularIndices, [0, 1, 2])
  }

  func testTabBarCompactionCanBeCancelledDuringLeadIn() {
    let configuration = AppleLiquidTabbarConfiguration(arguments: [
      "currentIndex": 0,
      "items": [["title": "Overview", "systemImage": "house.fill"]],
      "searchItem": ["title": "Add", "systemImage": "plus"],
    ])
    let model = AppleLiquidTabbarModel(configuration: configuration)

    model.setMinimized(true)
    model.setMinimized(false)

    XCTAssertFalse(model.isCompressing)
    XCTAssertFalse(model.isMinimized)
  }

  func testSelectingEitherCompactButtonExpandsTabBar() {
    let configuration = AppleLiquidTabbarConfiguration(arguments: [
      "currentIndex": 0,
      "items": [["title": "Overview", "systemImage": "house.fill"]],
      "searchItem": ["title": "Add", "systemImage": "plus"],
    ])
    let model = AppleLiquidTabbarModel(configuration: configuration)
    var expansionRequestCount = 0
    model.onExpansionRequested = {
      expansionRequestCount += 1
    }

    model.setMinimized(true, animated: false)
    model.selectCompactItem(at: 0)

    XCTAssertFalse(model.isMinimized)
    XCTAssertEqual(model.selectedIndex, 0)
    XCTAssertEqual(expansionRequestCount, 1)

    model.setMinimized(true, animated: false)
    model.selectCompactItem(at: model.searchIndex)

    XCTAssertFalse(model.isMinimized)
    XCTAssertEqual(model.selectedIndex, model.searchIndex)
    XCTAssertEqual(expansionRequestCount, 2)
  }

  func testTappingCompactGapExpandsTabBar() {
    let configuration = AppleLiquidTabbarConfiguration(arguments: [
      "currentIndex": 0,
      "items": [["title": "Overview", "systemImage": "house.fill"]],
      "searchItem": ["title": "Add", "systemImage": "plus"],
    ])
    let model = AppleLiquidTabbarModel(configuration: configuration)
    var expansionRequestCount = 0
    model.onExpansionRequested = {
      expansionRequestCount += 1
    }

    model.setMinimized(true, animated: false)
    model.expandFromCompactGap()

    XCTAssertFalse(model.isMinimized)
    XCTAssertEqual(expansionRequestCount, 1)
  }

  func testCustomChevronColorsReachNativeNavigationRows() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet configuration requires iOS 16 or newer.")
    }

    let content: [String: Any] = [
      "sections": [
        [
          "rows": [
            [
              "type": "picker",
              "title": "Theme",
              "options": ["Auto", "Dark"],
              "chevronColor": 0xFFFF9F0A
            ],
            [
              "type": "multiPicker",
              "title": "Kategorie",
              "options": ["Alle", "Garten"],
              "chevronColor": 0xFF0A84FF
            ],
            [
              "type": "navigation",
              "title": "Details",
              "chevronColor": 0xFF34C759,
              "content": [
                "sections": [
                  ["rows": [["type": "text", "title": "Detail"]]]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(
      snapshot.chevronARGBValues,
      [0xFFFF9F0A, 0xFF0A84FF, 0xFF34C759]
    )
  }

  func testSingleDetentDisablesAutomaticExpansion() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet configuration requires iOS 16 or newer.")
    }

    let oversizedRows = (0..<8).map { index in
      ["type": "text", "title": "Row \(index)"]
    }
    let automaticContent: [String: Any] = [
      "detents": ["initialHeight": 300.0],
      "sections": [["rows": oversizedRows]]
    ]
    let singleDetentContent: [String: Any] = [
      "detents": [
        "initialHeight": 300.0,
        "allowsAutomaticExpansion": false
      ],
      "sections": [["rows": oversizedRows]]
    ]

    let automaticSnapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: automaticContent
    )
    let singleDetentSnapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: singleDetentContent
    )

    XCTAssertNotNil(automaticSnapshot.preferredExpandedDetentHeight)
    XCTAssertEqual(singleDetentSnapshot.preferredDetentHeight, 300)
    XCTAssertNil(singleDetentSnapshot.preferredExpandedDetentHeight)
  }

  func testNavigationActivatesDetentsBeforeChangingPath() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet navigation requires iOS 16 or newer.")
    }

    let rootContent: [String: Any] = [
      "title": "Auftrag",
      "detents": [
        "initialHeight": 430.0,
        "expandedHeight": 660.0
      ]
    ]
    let destinationContent: [String: Any] = [
      "title": "Auftragsdetails",
      "detents": [
        "initialHeight": 300.0,
        "expandedHeight": 520.0
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport
      .navigationTransitionSnapshot(
        rootContentValue: rootContent,
        destinationContentValue: destinationContent
      )

    XCTAssertEqual(snapshot.events, ["detents", "path", "detents", "path"])
    XCTAssertEqual(snapshot.pathCounts, [1, 0])
    XCTAssertEqual(snapshot.activatedSelectedDetentHeights, [300, 660])
  }

  func testEqualRowInsetsResolveToEqualStandardFormSpacing() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet configuration requires iOS 16 or newer.")
    }

    let content: [String: Any] = [
      "sections": [
        [
          "rows": [
            [
              "type": "identity",
              "title": "Du",
              "role": "Helfer",
              "activityType": "Gartenarbeit",
              "rowHorizontalInset": 8.0
            ],
            [
              "type": "segmented",
              "title": "Layout",
              "options": ["List", "Grid"],
              "selectedOption": "List",
              "segmentedStyle": ["rowHorizontalInset": 8.0]
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(snapshot.standardFormRowHorizontalInsets, [8, 8])
    XCTAssertEqual(snapshot.identityAvatarSizes, [44])
    XCTAssertEqual(snapshot.identityIconSizes, [20])
    XCTAssertEqual(snapshot.identityCardPaddings, [10])
    XCTAssertEqual(snapshot.identityCornerRadii, [14])
    XCTAssertEqual(snapshot.identityBackgroundOpacities, [0.12])
    XCTAssertEqual(snapshot.identityVariantValues, ["legacy"])
  }

  func testIdentityCompositionParsesStatusAndRelatedPeople() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet configuration requires iOS 16 or newer.")
    }

    let content: [String: Any] = [
      "sections": [
        [
          "rows": [
            [
              "type": "identity",
              "title": "Gassi gehen",
              "avatarText": "G",
              "status": [
                "label": "Anfrage gesendet",
                "systemImage": "circle.fill",
                "foregroundColor": 0xFFBBD7FF,
                "backgroundColor": 0x262A82D7,
                "borderColor": 0xFF2A6DAD
              ],
              "relatedPeople": [
                [
                  "title": "Mara König",
                  "subtitle": "Auftraggeberin",
                  "avatarText": "M",
                  "badges": [
                    [
                      "label": "Verifiziert",
                      "systemImage": "checkmark.seal.fill",
                      "foregroundColor": 0xFF34C759
                    ]
                  ]
                ]
              ],
              "identityStyle": [
                "secondaryAvatarSize": 34.0,
                "contentSpacing": 12.0,
                "statusHorizontalPadding": 10.0,
                "statusVerticalPadding": 5.0,
                "badgeSpacing": 6.0
              ]
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(snapshot.identityStatusLabels, ["Anfrage gesendet"])
    XCTAssertEqual(snapshot.identityVariantValues, ["composed"])
    XCTAssertEqual(snapshot.identityRelatedPeopleCounts, [1])
    XCTAssertEqual(snapshot.estimatedRowHeights, [159])
  }

  func testIdentityLegacyVariantKeepsThePublishedCardShape() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet configuration requires iOS 16 or newer.")
    }

    let content: [String: Any] = [
      "sections": [
        [
          "rows": [
            [
              "type": "identity",
              "title": "Du",
              "role": "Helfer",
              "status": ["label": "Anfrage gesendet"],
              "relatedPeople": [
                ["title": "Zusatzinformation"]
              ],
              "identityVariant": "legacy"
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(snapshot.identityVariantValues, ["legacy"])
    XCTAssertEqual(snapshot.identityRelatedPeopleCounts, [1])
    XCTAssertEqual(snapshot.estimatedRowHeights, [94])
  }

  func testIdentityAndActionRowsUseTheSameDefaultOuterInset() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet configuration requires iOS 16 or newer.")
    }

    let content: [String: Any] = [
      "sections": [
        [
          "rows": [
            [
              "type": "identity",
              "title": "Du",
              "role": "Helfer",
              "activityType": "Gartenarbeit"
            ],
            [
              "type": "button",
              "title": "Öffnen",
              "buttonActionId": "open"
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(snapshot.resolvedFormRowHorizontalInsets, [16, 16])
  }

  @MainActor
  func testEqualInsetsKeepRenderedContentWithinSameHorizontalBounds() throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("Native sheet layout requires iOS 17 or newer.")
    }

    let content: [String: Any] = [
      "title": "Inset comparison",
      "detents": ["initialHeight": 500.0],
      "sections": [
        [
          "rows": [
            [
              "type": "identity",
              "title": "Du",
              "role": "Helfer",
              "activityType": "Gartenarbeit",
              "description": "Unterstützt den Auftrag vor Ort.",
              "tintColor": 0xFF0A84FF,
              "rowHorizontalInset": 8.0,
              "identityStyle": [
                "avatarSize": 48.0,
                "iconSize": 22.0,
                "cardPadding": 12.0,
                "cornerRadius": 16.0,
                "backgroundOpacity": 0.14
              ]
            ]
          ]
        ],
        [
          "rows": [
            [
              "type": "segmented",
              "title": "Layout",
              "options": ["List", "Grid"],
              "selectedOption": "List",
              "segmentedStyle": [
                "selectedBackgroundColor": 0x2634C759,
                "unselectedBackgroundColor": 0xFF34C759,
                "selectedTextColor": 0xFF34C759,
                "selectedBorderColor": 0x9934C759,
                "selectedShadowColor": 0x0AFFFFFF,
                "buttonHeight": 48.0,
                "cornerRadius": 16.0,
                "rowHorizontalInset": 8.0,
                "selectedShadowRadius": 8.0,
                "selectedShadowOffsetY": 2.0
              ]
            ]
          ]
        ]
      ]
    ]
    let host = UIHostingController(
      rootView: AppleLiquidSheetLayoutTestSupport.makePresentedSheet(
        contentValue: content
      )
    )
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))

    let sheetController = try XCTUnwrap(host.presentedViewController)
    sheetController.view.layoutIfNeeded()
    let collectionView: UICollectionView = try XCTUnwrap(
      firstSubview(of: UICollectionView.self, in: sheetController.view)
    )
    collectionView.collectionViewLayout.prepare()

    let rendererFormat = UIGraphicsImageRendererFormat()
    rendererFormat.scale = 1
    rendererFormat.preferredRange = .standard
    let renderer = UIGraphicsImageRenderer(
      bounds: sheetController.view.bounds,
      format: rendererFormat
    )
    let image = renderer.image { _ in
      sheetController.view.drawHierarchy(
        in: sheetController.view.bounds,
        afterScreenUpdates: true
      )
    }
    let renderedRowBounds = wideVisibleHorizontalBounds(
      in: image,
      minimumComponent: 5,
      minimumWidth: 300,
      minimumConsecutiveRows: 20
    )
    XCTAssertEqual(renderedRowBounds.count, 2)
    let identityBounds = try XCTUnwrap(renderedRowBounds.first)
    let segmentedBounds = try XCTUnwrap(renderedRowBounds.last)

    XCTAssertEqual(
      identityBounds.lowerBound,
      segmentedBounds.lowerBound,
      accuracy: 0.5
    )
    XCTAssertEqual(
      identityBounds.upperBound,
      segmentedBounds.upperBound,
      accuracy: 0.5
    )

    let attachment = XCTAttachment(image: image)
    attachment.name = "identity-segmented-inset-comparison"
    attachment.lifetime = .keepAlways
    add(attachment)

    withExtendedLifetime(window) {}
  }

  @MainActor
  func testIdentityAndActionRowsKeepRenderedContentWithinSameHorizontalBounds() throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("Native sheet layout requires iOS 17 or newer.")
    }

    let content: [String: Any] = [
      "title": "Identity and action",
      "detents": ["initialHeight": 500.0],
      "sections": [
        [
          "rows": [
            [
              "type": "identity",
              "title": "Du",
              "role": "Helfer",
              "activityType": "Gartenarbeit",
              "rowHorizontalInset": 8.0,
              "identityStyle": [
                "avatarSize": 48.0,
                "iconSize": 22.0,
                "cardPadding": 12.0,
                "cornerRadius": 16.0,
                "backgroundOpacity": 0.14
              ]
            ]
          ]
        ],
        [
          "rows": [
            [
              "type": "button",
              "title": "Öffnen",
              "buttonActionId": "open",
              "tintColor": 0xFF0A84FF,
              "buttonStyle": [
                "backgroundColor": 0xFF0A84FF,
                "foregroundColor": 0xFFFFFFFF,
                "borderColor": 0xFF0A84FF,
                "buttonHeight": 48.0,
                "cornerRadius": 16.0,
                "rowHorizontalInset": 8.0,
                "rowTopInset": 0.0,
                "rowBottomInset": 0.0
              ]
            ]
          ]
        ]
      ]
    ]
    let host = UIHostingController(
      rootView: AppleLiquidSheetLayoutTestSupport.makePresentedSheet(
        contentValue: content
      )
    )
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))

    let sheetController = try XCTUnwrap(host.presentedViewController)
    sheetController.view.layoutIfNeeded()
    let rendererFormat = UIGraphicsImageRendererFormat()
    rendererFormat.scale = 1
    rendererFormat.preferredRange = .standard
    let renderer = UIGraphicsImageRenderer(
      bounds: sheetController.view.bounds,
      format: rendererFormat
    )
    let image = renderer.image { _ in
      sheetController.view.drawHierarchy(
        in: sheetController.view.bounds,
        afterScreenUpdates: true
      )
    }
    let renderedRowBounds = wideVisibleHorizontalBounds(
      in: image,
      minimumComponent: 5,
      minimumWidth: 300,
      minimumConsecutiveRows: 20,
      // Compare the blue content fills, excluding native Form section chrome.
      minimumBlueRedDifference: 24
    )
    XCTAssertEqual(renderedRowBounds.count, 2)
    let identityBounds = try XCTUnwrap(renderedRowBounds.first)
    let actionBounds = try XCTUnwrap(renderedRowBounds.last)

    XCTAssertEqual(
      identityBounds.lowerBound,
      actionBounds.lowerBound,
      accuracy: 0.5
    )
    XCTAssertEqual(
      identityBounds.upperBound,
      actionBounds.upperBound,
      accuracy: 0.5
    )

    let attachment = XCTAttachment(image: image)
    attachment.name = "identity-action-inset-comparison"
    attachment.lifetime = .keepAlways
    add(attachment)

    withExtendedLifetime(window) {}
  }

  @MainActor
  func testStructuredRowsRenderWithinCalculatedDetent() throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("Structured native sheet layout requires iOS 17 or newer.")
    }

    let content: [String: Any] = [
      "title": "Auftrag",
      "detents": ["initialHeight": 600.0],
      "sections": [
        [
          "title": "Übersicht",
          "rows": [
            [
              "type": "identity",
              "title": "Du",
              "role": "Helfer",
              "activityType": "Gartenarbeit",
              "description": "Unterstützt den Auftrag vor Ort.",
              "systemImage": "person.fill",
              "tintColor": 0xFF0A84FF,
              "rowHorizontalInset": 8,
              "identityStyle": [
                "avatarSize": 48.0,
                "iconSize": 22.0,
                "cardPadding": 12.0,
                "cornerRadius": 16.0,
                "backgroundOpacity": 0.14
              ]
            ],
            [
              "type": "factsGrid",
              "title": "Auftrag",
              "columns": 3,
              "facts": [
                ["label": "Termin", "value": "Mo · 18:00"],
                ["label": "Ort", "value": "2,4 km"],
                ["label": "Vergütung", "value": "18 €/Std."]
              ]
            ],
            [
              "type": "timeline",
              "title": "Status",
              "currentStepIndex": 1,
              "steps": [
                ["title": "Angefragt"],
                ["title": "Bestätigt"]
              ]
            ],
            [
              "type": "button",
              "title": "Öffnen",
              "buttonActionId": "structured-layout-button"
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(snapshot.groupCount, 2)
    XCTAssertEqual(snapshot.rowCounts, [3, 1])
    XCTAssertEqual(snapshot.rowKinds, ["identity", "factsGrid", "timeline", "button"])
    XCTAssertEqual(snapshot.identityRoles, ["Helfer"])
    XCTAssertEqual(
      snapshot.identityDescriptions,
      ["Unterstützt den Auftrag vor Ort."]
    )
    XCTAssertEqual(snapshot.identityRowHorizontalInsets, [8])
    XCTAssertEqual(snapshot.identityAvatarSizes, [48])
    XCTAssertEqual(snapshot.identityIconSizes, [22])
    XCTAssertEqual(snapshot.identityCardPaddings, [12])
    XCTAssertEqual(snapshot.identityCornerRadii, [16])
    XCTAssertEqual(snapshot.identityBackgroundOpacities, [0.14])
    XCTAssertEqual(
      snapshot.resolvedFormRowHorizontalInsets,
      [8, 16, 16, 16]
    )
    XCTAssertEqual(snapshot.estimatedRowHeights.first, 136)
    XCTAssertEqual(snapshot.timelineCurrentStepIndices, [1])
    XCTAssertEqual(snapshot.factColumnCounts, [3])

    let host = UIHostingController(
      rootView: AppleLiquidSheetLayoutTestSupport.makePresentedSheet(
        contentValue: content
      )
    )
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))

    let sheetController = try XCTUnwrap(host.presentedViewController)
    sheetController.view.layoutIfNeeded()
    let collectionView: UICollectionView = try XCTUnwrap(
      firstSubview(of: UICollectionView.self, in: sheetController.view)
    )
    collectionView.collectionViewLayout.prepare()

    let lastSection = collectionView.numberOfSections - 1
    let lastItem = collectionView.numberOfItems(inSection: lastSection) - 1
    let lastRowAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForItem(
        at: IndexPath(item: lastItem, section: lastSection)
      )
    )
    let renderedBottom = collectionView.convert(
      lastRowAttributes.frame,
      to: sheetController.view
    ).maxY
    let resolvedDetentHeight = sheetController.view.bounds.height -
      sheetController.view.safeAreaInsets.bottom
    let renderedRowHeights = (0..<collectionView.numberOfSections).flatMap {
      section in
      (0..<collectionView.numberOfItems(inSection: section)).compactMap {
        item in
        collectionView.collectionViewLayout.layoutAttributesForItem(
          at: IndexPath(item: item, section: section)
        )?.frame.height
      }
    }

    XCTAssertLessThanOrEqual(
      try XCTUnwrap(renderedRowHeights.first),
      try XCTUnwrap(snapshot.estimatedRowHeights.first),
      "The estimated identity height must contain its rendered description."
    )
    XCTAssertLessThanOrEqual(
      renderedBottom,
      resolvedDetentHeight + 1,
      "The calculated detent must fully contain all structured rows. " +
        "Rendered row heights: \(renderedRowHeights); " +
        "estimated row heights: \(snapshot.estimatedRowHeights)."
    )
    XCTAssertEqual(
      resolvedDetentHeight,
      snapshot.preferredDetentHeight,
      accuracy: 1
    )

    withExtendedLifetime(window) {}
  }

  @MainActor
  func testCollapsibleTimelineUsesCompactWindowAndCalculatedDetent() throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("Collapsible native timeline requires iOS 17 or newer.")
    }

    let content: [String: Any] = [
      "title": "Timeline",
      "sections": [
        [
          "title": "Aktueller Status",
          "rows": [
            [
              "type": "timeline",
              "title": "Aktueller Status",
              "currentStepIndex": 2,
              "collapsedStepLimit": 3,
              "initiallyExpanded": false,
              "expandLabel": "Alle Schritte anzeigen",
              "collapseLabel": "Weniger anzeigen",
              "steps": [
                ["title": "Angefragt"],
                ["title": "Bestätigt"],
                ["title": "Unterwegs"],
                ["title": "In Arbeit"],
                ["title": "Erledigt"]
              ]
            ],
            [
              "type": "button",
              "title": "Öffnen",
              "buttonActionId": "timeline-layout-button"
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(snapshot.rowKinds, ["timeline", "button"])
    XCTAssertEqual(snapshot.timelineCollapsedStepLimits, [3])
    XCTAssertEqual(snapshot.timelineInitiallyExpandedValues, [false])
    XCTAssertEqual(snapshot.timelineExpandLabels, ["Alle Schritte anzeigen"])
    XCTAssertEqual(snapshot.timelineCollapseLabels, ["Weniger anzeigen"])
    XCTAssertEqual(
      snapshot.timelineCollapsedVisibleStepTitles,
      [["Bestätigt", "Unterwegs", "In Arbeit"]]
    )
    XCTAssertEqual(snapshot.timelineExpandedVisibleStepCounts, [5])
    XCTAssertGreaterThan(
      try XCTUnwrap(snapshot.timelineExpandedHeights.first),
      try XCTUnwrap(snapshot.timelineCollapsedHeights.first)
    )

    let host = UIHostingController(
      rootView: AppleLiquidSheetLayoutTestSupport.makePresentedSheet(
        contentValue: content
      )
    )
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))

    let sheetController = try XCTUnwrap(host.presentedViewController)
    sheetController.view.layoutIfNeeded()
    let collectionView: UICollectionView = try XCTUnwrap(
      firstSubview(of: UICollectionView.self, in: sheetController.view)
    )
    collectionView.collectionViewLayout.prepare()

    let lastSection = collectionView.numberOfSections - 1
    let lastItem = collectionView.numberOfItems(inSection: lastSection) - 1
    let lastRowAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForItem(
        at: IndexPath(item: lastItem, section: lastSection)
      )
    )
    let renderedBottom = collectionView.convert(
      lastRowAttributes.frame,
      to: sheetController.view
    ).maxY
    let resolvedDetentHeight = sheetController.view.bounds.height -
      sheetController.view.safeAreaInsets.bottom

    XCTAssertLessThanOrEqual(
      renderedBottom,
      resolvedDetentHeight + 1,
      "The collapsed timeline and toggle must fit the calculated detent."
    )
    XCTAssertEqual(
      resolvedDetentHeight,
      snapshot.preferredDetentHeight,
      accuracy: 1
    )

    withExtendedLifetime(window) {}
  }

  @MainActor
  func testExactButtonSpacingRenderedHeightMatchesDetent() throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("Exact native section spacing requires iOS 17 or newer.")
    }

    let content: [String: Any] = [
      "title": "Layout test",
      "sectionSpacing": 4.0,
      "sections": [
        [
          "title": "First",
          "titleHorizontalInset": 8.0,
          "titleSpacing": 0.0,
          "rows": [
            ["type": "text", "title": "First row"]
          ]
        ],
        [
          "title": "Second",
          "titleSpacing": 6.0,
          "rows": [
            ["type": "text", "title": "Second row"]
          ]
        ],
        [
          "title": "Actions",
          "rows": [
            ["type": "text", "title": "Last regular row"],
            [
              "type": "button",
              "title": "Continue",
              "buttonActionId": "layout-test-button",
              "buttonStyle": [
                "rowTopInset": 16.0,
                "rowBottomInset": 4.0
              ]
            ]
          ]
        ]
      ]
    ]
    let snapshot = AppleLiquidSheetLayoutTestSupport.snapshot(
      contentValue: content
    )

    XCTAssertEqual(snapshot.groupCount, 4)
    XCTAssertEqual(snapshot.rowCounts, [2, 2, 1, 1])
    XCTAssertEqual(snapshot.spacingAfterGroups, [4, 4, 0, 0])
    XCTAssertEqual(snapshot.lastButtonTopInset, 16)
    XCTAssertEqual(snapshot.lastButtonBottomInset, 4)
    XCTAssertTrue(snapshot.removesBottomContentMargin)

    let host = UIHostingController(
      rootView: AppleLiquidSheetLayoutTestSupport.makePresentedSheet(
        contentValue: content
      )
    )
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))

    let sheetController = try XCTUnwrap(host.presentedViewController)
    sheetController.view.layoutIfNeeded()

    let collectionView: UICollectionView = try XCTUnwrap(
      firstSubview(of: UICollectionView.self, in: sheetController.view)
    )
    XCTAssertEqual(collectionView.numberOfSections, snapshot.groupCount)
    XCTAssertEqual(
      (0..<collectionView.numberOfSections).map {
        collectionView.numberOfItems(inSection: $0)
      },
      snapshot.rowCounts
    )

    collectionView.collectionViewLayout.prepare()
    let firstHeaderAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(
        ofKind: UICollectionView.elementKindSectionHeader,
        at: IndexPath(item: 0, section: 0)
      )
    )
    let secondHeaderAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(
        ofKind: UICollectionView.elementKindSectionHeader,
        at: IndexPath(item: 0, section: 1)
      )
    )
    let firstHeaderView = try XCTUnwrap(
      collectionView.supplementaryView(
        forElementKind: UICollectionView.elementKindSectionHeader,
        at: IndexPath(item: 0, section: 0)
      )
    )
    let secondHeaderView = try XCTUnwrap(
      collectionView.supplementaryView(
        forElementKind: UICollectionView.elementKindSectionHeader,
        at: IndexPath(item: 0, section: 1)
      )
    )
    let firstHeaderContentFrame = try XCTUnwrap(
      smallestVisibleLeafFrame(in: firstHeaderView, relativeTo: collectionView)
    )
    let secondHeaderContentFrame = try XCTUnwrap(
      smallestVisibleLeafFrame(in: secondHeaderView, relativeTo: collectionView)
    )
    let firstRowAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForItem(
        at: IndexPath(item: 0, section: 0)
      )
    )
    let secondRowAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForItem(
        at: IndexPath(item: 0, section: 1)
      )
    )
    XCTAssertEqual(
      firstRowAttributes.frame.minY - firstHeaderContentFrame.maxY,
      0,
      accuracy: 0.5
    )
    XCTAssertEqual(
      firstHeaderContentFrame.minX - firstRowAttributes.frame.minX,
      8,
      accuracy: 0.5
    )
    XCTAssertEqual(
      secondRowAttributes.frame.minY - secondHeaderContentFrame.maxY,
      6,
      accuracy: 0.5
    )
    XCTAssertEqual(
      secondHeaderAttributes.frame.height - firstHeaderAttributes.frame.height,
      6,
      accuracy: 0.5
    )

    for section in 0...1 {
      let spacerAttributes = try XCTUnwrap(
        collectionView.collectionViewLayout.layoutAttributesForItem(
          at: IndexPath(item: 1, section: section)
        )
      )
      XCTAssertEqual(spacerAttributes.frame.height, 4, accuracy: 0.5)
    }

    let lastSection = collectionView.numberOfSections - 1
    let lastItem = collectionView.numberOfItems(inSection: lastSection) - 1
    let lastRowAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForItem(
        at: IndexPath(item: lastItem, section: lastSection)
      )
    )
    let lastRowFrameInSheet = collectionView.convert(
      lastRowAttributes.frame,
      to: sheetController.view
    )
    let renderedTotalHeight = lastRowFrameInSheet.maxY
    let resolvedDetentHeight = sheetController.view.bounds.height -
      sheetController.view.safeAreaInsets.bottom
    let geometrySummary =
      "sheetFrame=\(sheetController.view.frame), " +
      "sheetBounds=\(sheetController.view.bounds), " +
      "safeArea=\(sheetController.view.safeAreaInsets), " +
      "collectionFrame=\(collectionView.frame), " +
      "lastRowInSheet=\(lastRowFrameInSheet)"
    let layoutSummary = collectionView.collectionViewLayout
      .layoutAttributesForElements(
        in: CGRect(
          x: 0,
          y: 0,
          width: collectionView.bounds.width,
          height: lastRowAttributes.frame.maxY + 1
        )
      )?
      .sorted { $0.frame.minY < $1.frame.minY }
      .map { attributes in
        "\(attributes.representedElementCategory.rawValue):" +
          "\(attributes.indexPath.section)/\(attributes.indexPath.item)=" +
          "\(attributes.frame.minY)...\(attributes.frame.maxY)"
      }
      .joined(separator: ", ") ?? "no layout attributes"

    XCTAssertEqual(
      renderedTotalHeight,
      snapshot.preferredDetentHeight,
      accuracy: 1,
      "\(geometrySummary). Layout: \(layoutSummary)"
    )
    XCTAssertEqual(
      resolvedDetentHeight,
      snapshot.preferredDetentHeight,
      accuracy: 1
    )
    XCTAssertEqual(
      snapshot.preferredDetentHeight,
      snapshot.estimatedDetentHeight.rounded(.up),
      accuracy: 1
    )

    withExtendedLifetime(window) {}
  }

  @MainActor
  func testSliderDirectionalInsetsRenderIndependently() throws {
    guard #available(iOS 16.0, *) else {
      throw XCTSkip("Native sheet layout requires iOS 16 or newer.")
    }

    let content: [String: Any] = [
      "title": "Inset test",
      "sections": [
        [
          "title": "Kategorie",
          "titleLeadingInset": 8.0,
          "titleTrailingInset": 24.0,
          "rows": [
            [
              "type": "slider",
              "title": "Distanz",
              "sliderValue": 5.0,
              "min": 0.0,
              "max": 10.0,
              "rowLeadingInset": 8.0,
              "rowTrailingInset": 24.0
            ]
          ]
        ]
      ]
    ]
    let host = UIHostingController(
      rootView: AppleLiquidSheetLayoutTestSupport.makePresentedSheet(
        contentValue: content
      )
    )
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))

    let sheetController = try XCTUnwrap(host.presentedViewController)
    sheetController.view.layoutIfNeeded()
    let collectionView: UICollectionView = try XCTUnwrap(
      firstSubview(of: UICollectionView.self, in: sheetController.view)
    )
    collectionView.collectionViewLayout.prepare()

    let sliderRowIndexPath = IndexPath(item: 0, section: 0)
    let sliderRowAttributes = try XCTUnwrap(
      collectionView.collectionViewLayout.layoutAttributesForItem(
        at: sliderRowIndexPath
      )
    )
    let sliderCell = try XCTUnwrap(
      collectionView.cellForItem(at: sliderRowIndexPath)
    )
    let slider = try XCTUnwrap(
      firstSubview(of: UISlider.self, in: sliderCell)
    )
    let sliderFrame = slider.convert(slider.bounds, to: collectionView)

    XCTAssertEqual(
      sliderFrame.minX - sliderRowAttributes.frame.minX,
      8,
      accuracy: 0.5
    )
    XCTAssertEqual(
      sliderRowAttributes.frame.maxX - sliderFrame.maxX,
      24,
      accuracy: 0.5
    )

    withExtendedLifetime(window) {}
  }

  private func firstSubview<ViewType: UIView>(
    of type: ViewType.Type,
    in view: UIView
  ) -> ViewType? {
    if let matchingView = view as? ViewType {
      return matchingView
    }

    for subview in view.subviews {
      if let matchingView = firstSubview(of: type, in: subview) {
        return matchingView
      }
    }

    return nil
  }

  private func smallestVisibleLeafFrame(
    in view: UIView,
    relativeTo ancestor: UIView
  ) -> CGRect? {
    let smallestLeaf = allSubviews(of: view)
      .filter { candidate in
        candidate.subviews.isEmpty &&
          !candidate.isHidden &&
          candidate.alpha > 0 &&
          candidate.bounds.width > 1 &&
          candidate.bounds.height > 1
      }
      .min { lhs, rhs in
        lhs.bounds.height < rhs.bounds.height
      }

    guard let smallestLeaf else {
      return nil
    }

    return smallestLeaf.convert(smallestLeaf.bounds, to: ancestor)
  }

  private func allSubviews(of view: UIView) -> [UIView] {
    view.subviews + view.subviews.flatMap(allSubviews)
  }

  private func wideVisibleHorizontalBounds(
    in image: UIImage,
    minimumComponent: UInt8,
    minimumWidth: Int,
    minimumConsecutiveRows: Int,
    minimumBlueRedDifference: Int = 0
  ) -> [ClosedRange<CGFloat>] {
    guard let sourceImage = image.cgImage else {
      return []
    }

    let width = sourceImage.width
    let height = sourceImage.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    var pixels = [UInt8](
      repeating: 0,
      count: height * bytesPerRow
    )
    guard let context = CGContext(
      data: &pixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return []
    }

    context.draw(
      sourceImage,
      in: CGRect(x: 0, y: 0, width: width, height: height)
    )
    var consecutiveBounds: [(firstX: Int, lastX: Int)] = []
    var groups: [[(firstX: Int, lastX: Int)]] = []

    for pixelY in 0..<height {
      let rowStart = pixelY * bytesPerRow
      let visibleXs = (0..<width).filter { x in
        let pixelStart = rowStart + (x * bytesPerPixel)
        let isVisible = pixels[pixelStart] >= minimumComponent ||
          pixels[pixelStart + 1] >= minimumComponent ||
          pixels[pixelStart + 2] >= minimumComponent

        if minimumBlueRedDifference > 0 {
          return isVisible &&
            Int(pixels[pixelStart + 2]) - Int(pixels[pixelStart]) >=
              minimumBlueRedDifference
        }
        return isVisible
      }

      if let firstX = visibleXs.first,
        let lastX = visibleXs.last,
        lastX - firstX >= minimumWidth
      {
        consecutiveBounds.append((firstX, lastX))
      } else if !consecutiveBounds.isEmpty {
        groups.append(consecutiveBounds)
        consecutiveBounds = []
      }
    }

    if !consecutiveBounds.isEmpty {
      groups.append(consecutiveBounds)
    }

    return groups.compactMap { group in
      guard group.count >= minimumConsecutiveRows else {
        return nil
      }

      let firstX = group.map(\.firstX).min() ?? 0
      let lastX = group.map(\.lastX).max() ?? 0
      return CGFloat(firstX)...CGFloat(lastX)
    }
  }
}

private final class SwitchGroupTestMessenger: NSObject, FlutterBinaryMessenger {
  var handler: FlutterBinaryMessageHandler?
  var events: [FlutterMethodCall] = []
  private let codec = FlutterStandardMethodCodec.sharedInstance()

  func send(onChannel channel: String, message: Data?) {
    if let message = message { events.append(codec.decodeMethodCall(message)) }
  }

  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
    send(onChannel: channel, message: message)
    callback?(nil)
  }

  func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection {
    self.handler = handler
    return 1
  }

  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) { handler = nil }

  func update(_ arguments: [String: Any]) {
    handler?(codec.encode(FlutterMethodCall(methodName: "updateConfiguration", arguments: arguments)), { _ in })
  }
}

private final class BadgeWriteCountingTabBar: UITabBar {
  var appearanceWrites = 0
  override var standardAppearance: UITabBarAppearance {
    didSet { appearanceWrites += 1 }
  }
  @available(iOS 15.0, *)
  override var scrollEdgeAppearance: UITabBarAppearance? {
    didSet { appearanceWrites += 1 }
  }
}

private final class BadgeWriteCountingTabBarItem: UITabBarItem {
  var badgeWrites = 0
  override var badgeValue: String? { didSet { badgeWrites += 1 } }
  override var badgeColor: UIColor? { didSet { badgeWrites += 1 } }
  override func setBadgeTextAttributes(_ textAttributes: [NSAttributedString.Key: Any]?,
    for state: UIControl.State) {
    badgeWrites += 1
    super.setBadgeTextAttributes(textAttributes, for: state)
  }
}
