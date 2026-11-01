import Flutter
import UIKit

public class AppleLiquidTabbarPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = AppleLiquidTabbarPlatformViewFactory(
      messenger: registrar.messenger()
    )

    registrar.register(factory, withId: AppleLiquidTabbarConstants.tabBarViewType)
    registrar.register(
      AppleLiquidSwitchPlatformViewFactory(messenger: registrar.messenger()),
      withId: AppleLiquidTabbarConstants.switchViewType
    )
    registrar.register(
      AppleLiquidSwitchGroupPlatformViewFactory(messenger: registrar.messenger()),
      withId: AppleLiquidTabbarConstants.switchGroupViewType
    )
    registrar.register(
      AppleLiquidSliderPlatformViewFactory(messenger: registrar.messenger()),
      withId: AppleLiquidTabbarConstants.sliderViewType
    )
    registrar.register(
      AppleLiquidSurfacePlatformViewFactory(),
      withId: AppleLiquidTabbarConstants.surfaceViewType
    )
    registrar.register(
      AppleConcentricRectanglePlatformViewFactory(),
      withId: AppleLiquidTabbarConstants.concentricRectangleViewType
    )
    FlutterMethodChannel(
      name: AppleLiquidTabbarConstants.symbolChannelName,
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler(
      AppleLiquidSymbolRenderer.handle
    )
    AppleLiquidSheetPresenter.register(
      messenger: registrar.messenger()
    )
    AppleLiquidPopoverPresenter.register(with: registrar)
    AppleLiquidToastPresenter.register(
      messenger: registrar.messenger()
    )
  }
}
