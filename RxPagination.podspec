Pod::Spec.new do |spec|
  spec.name           = "RxPagination"
  spec.version        = "0.0.3"
  spec.summary        = "Handle paginated APIs easily, based on RxSwift Action"
  spec.description    = <<-DESC
    Handle paginated APIs easily, based on RxSwift Action. Including 3 pagination styles.
                        DESC

  spec.homepage       = "https://github.com/khoi-truong/RxPagination"
  spec.license        = { :type => "MIT", :file => "LICENSE" }
  spec.author         = { "Khoi Truong" => "khoi.truongminh@gmail.com" }
  
  spec.swift_version  = "5.0"
  spec.platform       = :ios, "12.0"

  spec.source         = { :git => "https://github.com/khoi-truong/RxPagination.git",
                          :tag => spec.version.to_s }
  spec.source_files   = "Sources/**/*.{swift}"

  spec.frameworks  = "Foundation"
  spec.dependency "RxSwift", "~> 6.0"
  spec.dependency "RxCocoa", "~> 6.0"
  spec.dependency "RxSwiftExt", "~> 6.0"
  spec.dependency "RxOptional", "~> 5.0"
  spec.dependency "Action", "~> 5.0"

end
