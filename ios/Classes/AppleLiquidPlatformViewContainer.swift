import UIKit

final class AppleLiquidPlatformViewContainer: UIView {
  private var hostedViewController: UIViewController?

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    isOpaque = false
  }

  required init?(coder: NSCoder) {
    nil
  }

  deinit {
    disposeHostedViewController()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()

    if window != nil {
      attachHostedViewControllerIfPossible()
    }
  }

  override func didMoveToSuperview() {
    super.didMoveToSuperview()

    if window != nil {
      attachHostedViewControllerIfPossible()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if window != nil {
      attachHostedViewControllerIfPossible()
    }
  }

  func host(_ viewController: UIViewController) {
    disposeHostedViewController()

    hostedViewController = viewController
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(viewController.view)

    NSLayoutConstraint.activate([
      viewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
      viewController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
      viewController.view.topAnchor.constraint(equalTo: topAnchor),
      viewController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    attachHostedViewControllerIfPossible()
  }

  func disposeHostedViewController() {
    guard let hostedViewController else {
      return
    }

    detachHostedViewControllerFromParent()
    hostedViewController.view.removeFromSuperview()
    self.hostedViewController = nil
  }

  private func attachHostedViewControllerIfPossible() {
    guard let hostedViewController else {
      return
    }

    guard let parentViewController = nearestViewController else {
      return
    }

    if hostedViewController.parent === parentViewController,
      hostedViewController.parent?.view.window === window {
      return
    }

    detachHostedViewControllerFromParent()
    parentViewController.addChild(hostedViewController)
    hostedViewController.didMove(toParent: parentViewController)
  }

  private func detachHostedViewControllerFromParent() {
    guard let hostedViewController, hostedViewController.parent != nil else {
      return
    }

    hostedViewController.willMove(toParent: nil)
    hostedViewController.removeFromParent()
  }

  private var nearestViewController: UIViewController? {
    var responder: UIResponder? = self

    while let nextResponder = responder?.next {
      if let viewController = nextResponder as? UIViewController {
        return viewController
      }

      responder = nextResponder
    }

    return nil
  }
}
