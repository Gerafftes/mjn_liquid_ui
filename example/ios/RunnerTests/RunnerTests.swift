import SwiftUI
import UIKit
import XCTest

@testable import mjn_liquid_ui

final class RunnerTests: XCTestCase {

  func testPluginCanBeCreated() {
    let plugin = AppleLiquidTabbarPlugin()
    XCTAssertNotNil(plugin)
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
          "rows": [
            ["type": "text", "title": "First row"]
          ]
        ],
        [
          "title": "Second",
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
}
