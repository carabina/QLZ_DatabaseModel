
Pod::Spec.new do |s|
s.name         = "QLZ_DatabaseModel"
s.version      = "0.1.1"
s.summary      = "iOS database."
s.homepage     = "https://github.com/qlz130514988/QLZ_DatabaseModel"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.author             = { "qlz130514988." => "https://github.com/qlz130514988" }
s.platform = :ios, "7.0"
s.source   = { :git => 'https://github.com/qlz130514988/QLZ_DatabaseModel.git', :tag => s.version, :submodules => true }
s.source_files  = "QLZ_DatabaseModel/*.{h,m}"
s.frameworks = "Foundation"
s.library = "sqlite3"
s.requires_arc = true
s.dependency "QLZ_JSONModel", "~> 0.1"

end
