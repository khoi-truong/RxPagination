//
//  CollectionEmptyTests.swift
//  RxPaginationTests
//
//  Created by Khoi Truong Minh on 10/12/20.
//  Copyright © 2020 Khoi Truong Minh. All rights reserved.
//

import Quick
import Nimble
@testable import RxPagination

final class CollectionEmptyExtensionSpec: QuickSpec {

    override func spec() {

        describe("Optional collection extension orEmpty()") {

            context("when the optional collection is empty") {

                let aCollection: [Int]? = []

                it("should return a unwrapped empty collection") {
                    expect(aCollection.orEmpty).to(beEmpty())
                }
            }

            context("when the optional collection is not empty") {

                let aCollection: [Int]? = [1, 2, 3]

                it("should return a unwrapped not empty collection") {
                    expect(aCollection.orEmpty).notTo(beEmpty())
                    expect(aCollection.orEmpty.count).to(equal(3))
                }
            }
        }

        describe("Optional collection extension replaceEmptyWithNil()") {

            context("when the optional collection is empty") {

                let aCollection: [Int]? = []

                it("should return nil") {
                    expect(aCollection.replaceEmptyWithNil()).to(beNil())
                }
            }

            context("when the optional collection is not empty") {

                let aCollection: [Int]? = [1, 2, 3]

                it("should return a unwrapped not empty collection") {
                    expect(aCollection.orEmpty).notTo(beEmpty())
                    expect(aCollection.orEmpty.count).to(equal(3))
                }
            }
        }

        describe("Collection extension replaceEmpty(with:)") {

            context("when the collection is empty") {

                let aCollection: [Int] = []

                it("should return the parameter collection") {
                    expect(aCollection.replaceEmpty(with: [1, 2])).to(equal([1, 2]))
                }
            }

            context("when the collection is not empty") {

                let aCollection: [Int] = [1, 2, 3]

                it("should return itself") {
                    expect(aCollection.replaceEmpty(with: [4, 5])).to(equal(aCollection))
                }
            }
        }

        describe("Collection extension replaceEmptyWithNil") {

            context("when the collection is empty") {

                let aCollection: [Int] = []

                it("should return nil") {
                    expect(aCollection.replaceEmptyWithNil()).to(beNil())
                }
            }

            context("when the collection is not empty") {

                let aCollection: [Int] = [1, 2, 3]

                it("should return itself") {
                    expect(aCollection.replaceEmptyWithNil()).to(equal(aCollection))
                }
            }
        }
    }
}
