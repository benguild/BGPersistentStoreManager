Pod::Spec.new do |s|
  s.name             = "BGPersistentStoreManager"
  s.version          = "1.0.4"
  s.homepage         = "https://github.com/benguild/BGPersistentStoreManager"
  s.summary          = "A simple singleton/wrapper/manager for the Apple iOS/macOS/etc. \"Core Data\" `NSPersistentStore` object/contexts."
  s.license          = 'MIT'
  s.author           = { "Ben Guild" => "email@benguild.com" }
  s.source           = { :git => "https://github.com/benguild/BGPersistentStoreManager.git", :tag => s.version.to_s }
  s.source_files     = 'BGPersistentStoreManager.{h,m}'
  s.social_media_url = 'https://twitter.com/benguild'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.frameworks = 'CoreData'

  s.dependency   'KCOrderedAccessorFix'

end
