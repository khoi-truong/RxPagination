//
//  PagingAction.swift
//  RxPagination
//
//  Created by Khoi Truong Minh on 10/9/20.
//  Copyright © 2020 Khoi Truong Minh. All rights reserved.
//

import Action
import Foundation
import RxCocoa
import RxOptional
import RxSwift
import RxSwiftExt

public protocol PagingResponse {
    associatedtype Item

    var items: [Item] { get }
    var page: Int { get }
    var itemsPerPage: Int { get }
    var totalPages: Int? { get }
}

extension PagingResponse {

    var mayHaveNext: Bool { totalPages.flatMap { page < $0 - 1 }.or(items.count == itemsPerPage) }
}

public struct RequestPage: Equatable {
    public let page: Int
    public let itemsPerPage: Int

    public init(page: Int, itemsPerPage: Int) {
        self.page = page
        self.itemsPerPage = itemsPerPage
    }
}

public final class PagingAction<Input, Response: PagingResponse> {

    public typealias Request = (Input, RequestPage?) -> Observable<Response>

    // MARK: - Inputs

    public let reload: PublishRelay<Input> = PublishRelay<Input>()
    public let next: PublishRelay<Input> = PublishRelay<Input>()

    // MARK: - Outputs

    public var errors: Observable<ActionError> { actionErrors.asObservable() }
    public var underlyingError: Observable<Error> { action.underlyingError }
    public var executing: Observable<Bool> { action.executing }
    public let allItems: Observable<[Response.Item]>
    public var items: Observable<[Response.Item]> { responses.map { $0.response.items } }
    public var hasNext: Observable<Bool> { hasNextRelay.asObservable() }

    // MARK: - Private

    private typealias ActionInput = (Request, Input, RequestPage?)
    private let action: Action<ActionInput, Response>
    private let actionErrors = PublishRelay<ActionError>()
    private let responses: Observable<(response: Response, type: ActionType)>
    private let nextPage = BehaviorRelay<RequestPage?>(value: nil)
    private let actionType = BehaviorRelay<ActionType?>(value: nil)
    private let hasNextRelay = BehaviorRelay<Bool>(value: true)
    private let disposeBag = DisposeBag()

    // MARK: - Init

    public convenience init(itemsPerPage: Int? = nil, request: @escaping Request) {
        self.init(itemsPerPage: itemsPerPage, removeDuplicates: nil, ofType: String.self, request: request)
    }

    public convenience init<S: Hashable>(itemsPerPage: Int? = nil,
                                         removeDuplicates keyForValue: @escaping ((Response.Item) -> S),
                                         request: @escaping Request) {
        self.init(itemsPerPage: itemsPerPage, removeDuplicates: keyForValue, ofType: S.self, request: request)
    }

    private init<S: Hashable>(itemsPerPage: Int? = nil,
                              removeDuplicates keyForValue: ((Response.Item) -> S)?,
                              ofType _: S.Type,
                              request: @escaping Request) {

        self.action = Action<ActionInput, Response> { request, input, next in request(input, next) }

        self.responses = action.elements
            .withLatestFrom(actionType) { response, type in type.flatMap { (response, $0) } }
            .filterNil()

        self.allItems = responses
            .scan([Response]()) { responses, element in
                switch element.type {
                case .next: return responses + [element.response]
                case .reload: return [element.response]
                }
            }
            .map { responses in responses.sorted(by: { $0.page < $1.page }).flatMap { $0.items } }
            .map { items in keyForValue.flatMap({ items.removeDuplicates(by: $0) }).or(items) }

        configPage()
        configActionType()
        configActionInputs(itemsPerPage: itemsPerPage, request: request)
        configActionErrors()
    }

    // MARK: - Private

    private enum ActionType {
        case reload
        case next
    }

    private func configPage() {

        Observable
            .merge(action.elements.map { $0.mayHaveNext ? RequestPage(page: $0.page + 1, itemsPerPage: $0.itemsPerPage) : nil },
                   reload.mapTo(nil))
            .bind(to: nextPage)
            .disposed(by: disposeBag)

        Observable
            .merge(action.elements.map { $0.mayHaveNext }, reload.mapTo(true))
            .bind(to: hasNextRelay)
            .disposed(by: disposeBag)
    }

    private func configActionType() {

        next
            .withLatestFrom(action.executing)
            .filter(!)
            .mapTo(.next)
            .bind(to: actionType)
            .disposed(by: disposeBag)

        reload
            .withLatestFrom(action.executing)
            .filter(!)
            .mapTo(.reload)
            .bind(to: actionType)
            .disposed(by: disposeBag)
    }

    private func configActionInputs(itemsPerPage: Int?, request: @escaping Request) {

        next
            .withLatestFrom(nextPage) { input, next in next.flatMap { (request, input, $0) } }
            .filterNil()
            .bind(to: action.inputs)
            .disposed(by: disposeBag)

        reload
            .map { input in (request, input, itemsPerPage.flatMap { RequestPage(page: 0, itemsPerPage: $0) }) }
            .bind(to: action.inputs)
            .disposed(by: disposeBag)
    }

    private func configActionErrors() {

        action.errors
            .bind(to: actionErrors)
            .disposed(by: disposeBag)

        next
            .withLatestFrom(nextPage)
            .filter { $0 == nil }
            .mapTo(ActionError.notEnabled)
            .bind(to: actionErrors)
            .disposed(by: disposeBag)
    }
}
