//
//  OptionalExtensionTests.swift
//  RxPaginationTests
//
//  Created by Khoi Truong Minh on 10/14/20.
//

import Quick
import Nimble
@testable import RxPagination

final class OptionalExtensionSpec: QuickSpec {

    override func spec() {

        describe("Optional extension or(_:) with unwrapped parameter") {

            context("when the optional is not nil") {

                let anOptional: Int? = 10

                it("should return its unwrapped value") {
                    let afterOr = anOptional.or(20)
                    expect(afterOr).to(equal(10))
                }
            }

            context("when the optional is nil") {

                let anOptional: Int? = nil

                it("should return the parameter") {
                    let afterOr = anOptional.or(20)
                    expect(afterOr).to(equal(20))
                }
            }
        }

        describe("Optional extension or(_:) with optional parameter") {

            context("when the optional is not nil") {

                let anOptional: Int? = 10

                it("should return its unwrapped value") {
                    let afterOrUnwarapped = anOptional.or(20)
                    expect(afterOrUnwarapped).to(equal(10))
                    let afterOrNil = anOptional.or(nil)
                    expect(afterOrNil).to(equal(10))
                }
            }

            context("when the optional is nil and the parameter is not nil") {

                let anOptional: Int? = nil

                it("should return the unwrapped parameter") {
                    let param: Int? = 20
                    let afterOr = anOptional.or(param)
                    expect(afterOr).to(equal(20))
                }
            }

            context("when the optional is nil and the parameter is nil") {

                let anOptional: Int? = nil

                it("should return the unwrapped parameter") {
                    let afterOr = anOptional.or(nil)
                    expect(afterOr).to(beNil())
                }
            }
        }
    }
}
