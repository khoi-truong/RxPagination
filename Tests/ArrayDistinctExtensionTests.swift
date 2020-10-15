//
//  ArrayDistinctExtensionTests.swift
//  RxPaginationTests
//
//  Created by Khoi Truong Minh on 10/14/20.
//

import Quick
import Nimble
@testable import RxPagination

final class ArrayDistinctExtensionSpec: QuickSpec {

    override func spec() {

        describe("Array extension distinct(by:)") {

            context("when the array is empty") {

                let anArray: [Item] = []

                it("should return itself") {
                    expect(anArray.removeDuplicates(by: { $0.id })).to(equal(anArray))
                }
            }

            context ("when the array is not empty and do not have duplicated items") {

                let anArray: [Item] = [
                    Item(id: 0, value: 0),
                    Item(id: 1, value: 10),
                    Item(id: 2, value: 20),
                    Item(id: 3, value: 30),
                    Item(id: 4, value: 40),
                    Item(id: 5, value: 50),
                    Item(id: 6, value: 60),
                    Item(id: 7, value: 70)
                ]

                it("should return itself") {
                    expect(anArray.removeDuplicates(by: { $0.id })).to(equal(anArray))
                }
            }

            context ("when the array is not empty and have duplicated items") {

                let anArray: [Item] = [
                    Item(id: 0, value: 0),
                    Item(id: 1, value: 10),
                    Item(id: 2, value: 20),
                    Item(id: 2, value: 50),
                    Item(id: 3, value: 30),
                    Item(id: 4, value: 40),
                    Item(id: 5, value: 50),
                    Item(id: 6, value: 60),
                    Item(id: 0, value: 80),
                    Item(id: 7, value: 70)
                ]

                let expectedArray: [Item] = [
                    Item(id: 0, value: 0),
                    Item(id: 1, value: 10),
                    Item(id: 2, value: 20),
                    Item(id: 3, value: 30),
                    Item(id: 4, value: 40),
                    Item(id: 5, value: 50),
                    Item(id: 6, value: 60),
                    Item(id: 7, value: 70)
                ]

                it("should return itself") {
                    expect(anArray.removeDuplicates(by: { $0.id })).to(equal(expectedArray))
                }
            }
        }
    }
}


struct Item: Equatable {
    let id: Int
    let value: Int
}
