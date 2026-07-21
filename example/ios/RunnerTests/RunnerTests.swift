import SwiftUI
import UIKit
import XCTest

@testable import mjn_liquid_ui

final class RunnerTests: XCTestCase {

  func testPluginCanBeCreated() {
    let plugin = AppleLiquidTabbarPlugin()
    XCTAssertNotNil(plugin)
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

  @MainActor
  func testStructuredRowsRenderWithinCalculatedDetent() throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("Structured native sheet layout requires iOS 17 or newer.")
    }

    let content: [String: Any] = [
      "title": "Auftrag",
      "sections": [
        [
          "title": "Übersicht",
          "rows": [
            [
              "type": "identity",
              "title": "Du",
              "role": "Helfer",
              "activityType": "Gartenarbeit",
              "systemImage": "person.fill",
              "tintColor": 0xFF0A84FF
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
}
