#
# Beeping.podspec — CocoaPods secondary distribution (BEE-81).
#
# SPM is the primary distribution channel (BEE-80, Package.swift).
# This podspec exists so Flutter plugins and React Native modules
# that still depend on CocoaPods can pull the framework via a Podfile.
#
# Local development consumption (until BEE-82 publishes a tagged
# release):
#
#   pod 'Beeping', :path => '../beeping-ios'
#
# Production consumption (post-BEE-82):
#
#   pod 'Beeping', :git => 'https://github.com/beeping-io/beeping-ios',
#                  :tag => '0.0.1'
#
# The `vendored_frameworks` path resolves relative to this podspec.
# Consumers must run `./build.sh` from the repo root before
# `pod install` so `dist/Beeping.xcframework` exists.
#

Pod::Spec.new do |s|
  s.name             = "Beeping"
  s.version          = File.read(File.join(__dir__, "VERSION")).strip
  s.summary          = "Swift SDK for data over sound (audible + ultrasonic) on iOS."
  s.description      = <<~DESC
    The iOS SDK for the Beeping Platform. Decode and emit short payloads
    transmitted over sound using the device speaker/microphone, locally via
    the C++ engine bridge or remotely through the Beeping Platform cloud.
    Actor-based Swift 6 public API with AsyncStream events.
  DESC
  s.homepage         = "https://github.com/beeping-io/beeping-ios"
  s.license          = { :type => "Apache-2.0", :file => "LICENSE" }
  s.author           = { "Beeping" => "opensource@beeping.io" }
  s.source           = {
    :git => "https://github.com/beeping-io/beeping-ios.git",
    :tag => s.version.to_s
  }

  s.platform         = :ios, "15.0"
  s.swift_versions   = ["6.0"]

  # The pre-built XCFramework produced by `./build.sh`. Contains both
  # the iOS device and iOS Simulator slices, with the C engine
  # (`BeepingCore`) symbols statically embedded — no extra
  # `dependency` declarations needed.
  s.vendored_frameworks = "dist/Beeping.xcframework"

  # The umbrella header lives inside the XCFramework's Headers dir.
  # We don't expose any source headers from the podspec itself.
end
