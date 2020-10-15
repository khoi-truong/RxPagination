//
//  RxPaginationTests.swift
//  RxPaginationTests
//
//  Created by Khoi Truong Minh on 10/9/20.
//  Copyright © 2020 Khoi Truong Minh. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxCocoa
import RxTest
import Action
@testable import RxPagination

final class PagingActionSpec: QuickSpec {

    override func spec() {

        var scheduler: TestScheduler!
        var sut: PagingAction<String, SampleResponse>!
        var mockResponse: PublishSubject<SampleResponse>!
        var disposeBag: DisposeBag!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            disposeBag = DisposeBag()
        }

        describe("PagingAction") {

            var actionInput: TestableObserver<String>!
            var requestPage: TestableObserver<RequestPage?>!
            var allItems: TestableObserver<[SampleItem]>!
            var items: TestableObserver<[SampleItem]>!
            var errors: TestableObserver<ActionError>!
            var underlyingError: TestableObserver<Error>!
            var executing: TestableObserver<Bool>!
            var hasNext: TestableObserver<Bool>!

            beforeEach {
                actionInput = scheduler.createObserver(String.self)
                requestPage = scheduler.createObserver(RequestPage?.self)
                allItems = scheduler.createObserver([SampleItem].self)
                items = scheduler.createObserver([SampleItem].self)
                errors = scheduler.createObserver(ActionError.self)
                underlyingError = scheduler.createObserver(Error.self)
                executing = scheduler.createObserver(Bool.self)
                hasNext = scheduler.createObserver(Bool.self)

                mockResponse = PublishSubject<SampleResponse>()
                sut = PagingAction<String, SampleResponse>(itemsPerPage: 3, removeDuplicates: { $0.id }) { (input, page) in
                    actionInput.onNext(input)
                    requestPage.onNext(page)
                    return mockResponse.asObservable()
                }

                sut.allItems.bind(to: allItems).disposed(by: disposeBag)
                sut.items.bind(to: items).disposed(by: disposeBag)
                sut.errors.bind(to: errors).disposed(by: disposeBag)
                sut.underlyingError.bind(to: underlyingError).disposed(by: disposeBag)
                sut.executing.bind(to: executing).disposed(by: disposeBag)
                sut.hasNext.bind(to: hasNext).disposed(by: disposeBag)
            }

            context("when paging action did not trigger") {

                it("should not emit any item") {
                    expect(allItems.events).to(beEmpty())
                    expect(items.events).to(beEmpty())
                }

                it("should not emit any error") {
                    expect(errors.events).to(beEmpty())
                    expect(underlyingError.events).to(beEmpty())
                }

                it("should not be executing") {
                    expect(executing.events.count).to(equal(1))
                    expect(executing.events.last?.value.element).to(beFalse())
                }

                it("should have next") {
                    expect(hasNext.events.count).to(equal(1))
                    expect(hasNext.events.last?.value.element).to(beTrue())
                }
            }

            context("when paging action triggerred reload") {

                beforeEach {
                    scheduler.scheduleAt(10) { sut.reload.accept("Trigger") }
                }

                it("should pass `Trigger` as input of the request") {
                    scheduler.start()
                    expect(actionInput.events.count).to(equal(1))
                    expect(actionInput.events.last?.value.element).to(equal("Trigger"))
                }

                it("should pass page 0 and 3 items per page as request page") {
                    scheduler.start()
                    expect(requestPage.events.count).to(equal(1))
                    expect(requestPage.events.last?.value.element).to(equal(RequestPage(page: 0, itemsPerPage: 3)))
                }

                it("should not emit any item or error immediately") {
                    scheduler.start()
                    expect(allItems.events).to(beEmpty())
                    expect(items.events).to(beEmpty())
                    expect(errors.events).to(beEmpty())
                    expect(underlyingError.events).to(beEmpty())
                }

                it("should be executing") {
                    scheduler.start()
                    expect(executing.events.last?.value.element).to(beTrue())
                }

                context("and paging action trigger next before getting any response") {

                    beforeEach {
                        scheduler.scheduleAt(15) { sut.next.accept("Next") }
                    }

                    it("should emit an error") {
                        scheduler.start()
                        expect(errors.events.last?.value.element).to(matchError(ActionError.notEnabled))
                    }
                }

                context("and paging action trigger another reload before getting any response") {

                    beforeEach {
                        scheduler.scheduleAt(15) { sut.reload.accept("Another reload") }
                    }

                    it("should emit an error") {
                        scheduler.start()
                        expect(errors.events.last?.value.element).to(matchError(ActionError.notEnabled))
                    }
                }
            }

            context("when paging action triggerred reload and got success response") {

                beforeEach {
                    scheduler.scheduleAt(10) { sut.reload.accept("Trigger") }
                    scheduler.scheduleAt(20) {
                        mockResponse.onNext(SampleResponse(items: pageItems[0], itemsPerPage: 3, page: 0))
                        mockResponse.onCompleted()
                        mockResponse = PublishSubject<SampleResponse>()
                    }
                }

                it("should emit first 3 items and no error") {
                    scheduler.start()
                    expect(allItems.events.count).to(equal(1))
                    expect(allItems.events.last?.value.element).to(equal(pageItems[0]))
                    expect(items.events.count).to(equal(1))
                    expect(items.events.last?.value.element).to(equal(pageItems[0]))
                    expect(errors.events).to(beEmpty())
                    expect(underlyingError.events).to(beEmpty())
                    expect(executing.events.last?.value.element).to(beFalse())
                    expect(hasNext.events.last?.value.element).to(beTrue())
                }

                context("and paging action triggered next") {

                    beforeEach {
                        scheduler.scheduleAt(30) { sut.next.accept("Next 1") }
                    }

                    it("should pass `Next 1` as input of the request") {
                        scheduler.start()
                        expect(actionInput.events.last?.value.element).to(equal("Next 1"))
                    }

                    it("should pass page 1 and 3 items per page as request page") {
                        scheduler.start()
                        expect(requestPage.events.last?.value.element).to(equal(RequestPage(page: 1, itemsPerPage: 3)))
                    }

                    it("should not emit any new item or error immediately") {
                        scheduler.start()
                        expect(allItems.events.count).to(equal(1))
                        expect(items.events.count).to(equal(1))
                        expect(errors.events).to(beEmpty())
                        expect(underlyingError.events).to(beEmpty())
                    }

                    it("should be executing") {
                        scheduler.start()
                        expect(executing.events.last?.value.element).to(beTrue())
                    }

                    context("and paging action got success response") {

                        beforeEach {
                            scheduler.scheduleAt(40) {
                                mockResponse.onNext(SampleResponse(items: pageItems[1], itemsPerPage: 3, page: 1))
                                mockResponse.onCompleted()
                                mockResponse = PublishSubject<SampleResponse>()
                            }
                        }

                        it("should emit next 3 items and no error") {
                            scheduler.start()
                            expect(allItems.events.last?.value.element).to(equal(pageItems[0] + pageItems[1]))
                            expect(items.events.last?.value.element).to(equal(pageItems[1]))
                            expect(errors.events).to(beEmpty())
                            expect(underlyingError.events).to(beEmpty())
                            expect(executing.events.last?.value.element).to(beFalse())
                            expect(hasNext.events.last?.value.element).to(beTrue())
                        }
                    }

                    context("and paging action got failure response") {

                        beforeEach {
                            scheduler.scheduleAt(40) {
                                mockResponse.onError(NSError(domain: "Error", code: 123, userInfo: nil))
                                mockResponse = PublishSubject<SampleResponse>()
                            }
                        }

                        it("should emit no item and an error") {
                            scheduler.start()
                            expect(allItems.events.last?.value.element).to(equal(pageItems[0]))
                            expect(items.events.count).to(equal(1))
                            expect(errors.events.last?.value.element).to(matchError(ActionError.self))
                            expect(underlyingError.events.last?.value.element).to(matchError(NSError(domain: "Error", code: 123, userInfo: nil)))
                            expect(executing.events.last?.value.element).to(beFalse())
                            expect(hasNext.events.last?.value.element).to(beTrue())
                        }
                    }

                    context("and paging action trigger another next before getting any response") {

                        beforeEach {
                            scheduler.scheduleAt(35) { sut.next.accept("Another Next") }
                        }

                        it("should emit an error") {
                            scheduler.start()
                            expect(errors.events.last?.value.element).to(matchError(ActionError.notEnabled))
                        }
                    }

                    context("and paging action trigger reload before getting any response") {

                        beforeEach {
                            scheduler.scheduleAt(35) { sut.reload.accept("Another reload") }
                        }

                        it("should emit an error") {
                            scheduler.start()
                            expect(errors.events.last?.value.element).to(matchError(ActionError.notEnabled))
                        }
                    }
                }

                context("and paging action triggered next 3 more times and received responses") {

                    beforeEach {
                        scheduler.scheduleAt(30) { sut.next.accept("Next 1") }
                        scheduler.scheduleAt(40) {
                            mockResponse.onNext(SampleResponse(items: pageItems[1], itemsPerPage: 3, page: 1))
                            mockResponse.onCompleted()
                            mockResponse = PublishSubject<SampleResponse>()
                        }
                        scheduler.scheduleAt(50) { sut.next.accept("Next 2") }
                        scheduler.scheduleAt(60) {
                            mockResponse.onNext(SampleResponse(items: pageItems[2], itemsPerPage: 3, page: 2))
                            mockResponse.onCompleted()
                            mockResponse = PublishSubject<SampleResponse>()
                        }
                        scheduler.scheduleAt(70) { sut.next.accept("Next 3") }
                    }

                    it("should emit an error") {
                        scheduler.start()
                        expect(errors.events.last?.value.element).to(matchError(ActionError.notEnabled))
                    }

                    it("should have 9 items in total") {
                        scheduler.start()
                        expect(allItems.events.last?.value.element?.count).to(equal(9))
                        expect(allItems.events.last?.value.element).to(equal(pageItems.flatMap { $0 }))
                    }
                }

                context("and paging action triggered next 1 more time with response and then reload") {

                    beforeEach {
                        scheduler.scheduleAt(30) { sut.next.accept("Next 1") }
                        scheduler.scheduleAt(40) {
                            mockResponse.onNext(SampleResponse(items: pageItems[1], itemsPerPage: 3, page: 1))
                            mockResponse.onCompleted()
                            mockResponse = PublishSubject<SampleResponse>()
                        }
                        scheduler.scheduleAt(50) { sut.reload.accept("Another reload") }
                    }

                    it("should pass page 0 as request page") {
                        scheduler.start()
                        expect(requestPage.events.last?.value.element).to(equal(RequestPage(page: 0, itemsPerPage: 3)))
                    }
                }
            }
        }
    }
}

private let pageItems = [
    [SampleItem(id: 0, value: 0), SampleItem(id: 1, value: 10), SampleItem(id: 2, value: 20)],
    [SampleItem(id: 3, value: 30), SampleItem(id: 4, value: 40), SampleItem(id: 5, value: 50)],
    [SampleItem(id: 6, value: 60), SampleItem(id: 7, value: 70), SampleItem(id: 8, value: 80)]
]

private struct SampleResponse: PagingResponse {
    let items: [SampleItem]
    let itemsPerPage: Int
    let page: Int
    let totalPages: Int? = 3
}

private struct SampleItem: Equatable {
    let id: Int
    let value: Int
}
