Pod::Spec.new do |spec|
  spec.name           = "RxPagination"
  spec.version        = "0.0.1"
  spec.summary        = "Handle paginated APIs easily, based on RxSwift Action"
  spec.description    = <<-DESC
    Handle paginated APIs easily, based on RxSwift Action. Including 3 pagination styles.
                        DESC

  spec.homepage       = "https://github.com/khoitruongminh/RxPagination"
  spec.license        = { :type => "MIT", :file => "LICENSE" }
  spec.author         = { "Khoi Truong Minh (Max)" => "khoi.truongminh@gmail.com" }
  
  spec.swift_version  = "5.0"
  spec.platform       = :ios, "12.0"

  spec.source         = { :git => "https://github.com/khoitruongminh/RxPagination.git",
                          :tag => spec.version.to_s }
  spec.source_files   = "Sources/**/*.{swift}"

  spec.frameworks  = "Foundation"
  spec.dependency "RxSwift", "~> 5.1.1"
  spec.dependency "RxCocoa", "~> 5.1.1"
  spec.dependency "RxSwiftExt", "~> 5.2.0"
  spec.dependency "RxOptional", "~> 4.1.0"
  spec.dependency "Action", "~> 4.1.0"

end
