#
#  Be sure to run `pod spec lint CBSearchKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "CBSearchKit"
  s.version      = "0.6.0"
  s.summary      = "Simple and flexible full text search for iOS and macOS. Supports the sqlite3 FTS3/4/5 engine."
  s.homepage     = "https://github.com/cbess/CBSearchKit"
  s.license      = "MIT"
  s.author             = { "C. Bess" => "" }

  # multiple platforms
  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.15"

  s.source       = { :git => "https://github.com/cbess/CBSearchKit.git", :tag => "v#{s.version}"}

  s.source_files  = "CBSearchKit/Classes/CBSearchKit/*.{h,m}", "CBSearchKit/sqlite3/*.{h,m}"
  s.requires_arc = true

  s.dependency "FMDB", "2.7.5"
  s.dependency "sqlite3", "3.38.0"
  s.dependency "sqlite3/fts"
  s.dependency "sqlite3/fts5"

end
