#
#  Be sure to run `pod spec lint QYHRetainCycleDetector.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "QYHRetainCycleDetector"
  spec.version      = "0.1.3"
  spec.summary      = "Library that helps with detecting retain cycles in iOS apps"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  

  spec.homepage     = "https://github.com/mLazyDaddy/QYHRetainCycleDetector"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See https://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  spec.license      = "BSD"
  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.author             = { "mLazyDaddy" => "50094063+mLazyDaddy@users.noreply.github.com" }
  # Or just: spec.author    = "mLazyDaddy"
  # spec.authors            = { "mLazyDaddy" => "50094063+mLazyDaddy@users.noreply.github.com" }
  # spec.social_media_url   = "https://twitter.com/mLazyDaddy"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # spec.platform     = :ios
  spec.platform     = :ios, "8.0"

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source       = { :git => "https://github.com/mLazyDaddy/QYHRetainCycleDetector.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  spec.source_files  = "QYHRetainCycleDetector", "QYHRetainCycleDetector/**/*.{h,m,mm}"

  
  spec.public_header_files = [
  'QYHRetainCycleDetector/Detector/QYHRetainCycleDetector.h',
  'QYHRetainCycleDetector/Detector/NSObject+QYHRCDObject.h',
  'QYHRetainCycleDetector/Detector/QYHRetainCycleFinder.h'
  ]
    
   

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  spec.frameworks  = "Foundation","UIKit","CoreFoundation"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  
  mrr_files = [
  'QYHRetainCycleDetector/Detector/NSObject+QYHRCDObject.h',
  'QYHRetainCycleDetector/Detector/NSObject+QYHRCDObject.m',
  'QYHRetainCycleDetector/Detector/QYHNodeEnumerator.h',
  'QYHRetainCycleDetector/Detector/QYHNodeEnumerator.mm',
  'QYHRetainCycleDetector/Detector/QYHRetainCycleFinder.h',
  'QYHRetainCycleDetector/Detector/QYHRetainCycleFinder.mm',
  'QYHRetainCycleDetector/Detector/QYHRetainCycleGragh.h',
  'QYHRetainCycleDetector/Detector/QYHRetainCycleGragh.mm',
  'QYHRetainCycleDetector/Layout/Block/QYHBlockStrongRelationDetector.h',
  'QYHRetainCycleDetector/Layout/Block/QYHBlockStrongRelationDetector.mm',
  'QYHRetainCycleDetector/Layout/Block/QYHNSBlockLayout.h',
  'QYHRetainCycleDetector/Layout/Block/QYHNSBlockLayout.mm',
  'QYHRetainCycleDetector/Layout/Class/QYHIvar.h',
  'QYHRetainCycleDetector/Layout/Class/QYHIvar.mm',
  'QYHRetainCycleDetector/Layout/Class/QYHNSObjectLayout.h',
  'QYHRetainCycleDetector/Layout/Class/QYHNSObjectLayout.mm',
  'QYHRetainCycleDetector/Wrapper/Block/QYHNSBlock.h',
  'QYHRetainCycleDetector/Wrapper/Block/QYHNSBlock.mm',
  'QYHRetainCycleDetector/Wrapper/Class/QYHNSObject.h',
  'QYHRetainCycleDetector/Wrapper/Class/QYHNSObject.mm'
  ]
  
  files = Pathname.glob("QYHRetainCycleDetector/**/*.{h,m,mm}")
  files = files.map {|file| file.to_path}
  files = files.reject {|file| mrr_files.include?(file)}
  spec.requires_arc = files.sort

end
