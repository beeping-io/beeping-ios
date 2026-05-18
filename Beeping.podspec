#
# Beeping.podspec — CocoaPods secondary distribution (BEE-81 + BEE-2258).
#
# SPM is the primary distribution channel (BEE-80, Package.swift). This
# podspec exists so Flutter plugins and React Native modules that still
# depend on CocoaPods can pull the framework via a Podfile.
#
# Production consumption (post-BEE-2258 trunk push):
#
#   pod 'Beeping', '~> 0.1'
#
# Local development consumption:
#
#   pod 'Beeping', :path => '../beeping-ios'
#
# The binary source is the same XCFramework zip that SPM consumers fetch
# from GitHub Releases (BEE-82). CocoaPods downloads + extracts it
# automatically — no `./build.sh` step required on the consumer side.
# The sha256 is checked against the trunk-published podspec by CocoaPods.
#

Pod::Spec.new do |s|
  s.name             = "Beeping"
  # VERSION may contain an `x-release-please-version` marker comment;
  # split on whitespace and take the first token so release-please can
  # bump the file without breaking podspec evaluation.
  s.version          = File.read(File.join(__dir__, "VERSION")).strip.split.first
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

  # http source: same XCFramework zip uploaded to the GitHub Release by
  # `release.yml`. The release pipeline (BEE-2259) also rewrites this
  # file post-build so each tag's podspec is self-consistent.
  s.source           = {
    :http   => "https://github.com/beeping-io/beeping-ios/releases/download/v#{s.version}/Beeping.xcframework.zip",
    :sha256 => "110988ad921a6a6d3a0dd7335cb894ba89d24fb2df0595344aed3e0efcf9f917"
  }

  s.platform         = :ios, "15.0"
  s.swift_versions   = ["6.0"]

  # The XCFramework lives at the root of the extracted zip (no `dist/`
  # prefix — CocoaPods extracts the http source into the pod's working
  # directory, not into the original repo layout). Contains both the
  # iOS device and iOS Simulator slices with the C engine (`BeepingCore`)
  # symbols statically embedded — no extra `dependency` declarations
  # needed.
  s.vendored_frameworks = "Beeping.xcframework"
end
