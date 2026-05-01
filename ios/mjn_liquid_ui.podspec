#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mjn_liquid_ui.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mjn_liquid_ui'
  s.version          = '0.1.5'
  s.summary          = 'Native-inspired Liquid Glass UI widgets for Flutter.'
  s.description      = <<-DESC
Embeds native iOS SwiftUI Liquid Glass controls in Flutter, including a dedicated TabRole.search tab.
                       DESC
  s.homepage         = 'https://pub.dev/packages/mjn_liquid_ui'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Christian Alexander Buschhoff' => 'mjn_liquid_ui' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'mjn_liquid_ui_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
