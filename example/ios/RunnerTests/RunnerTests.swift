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
