//
//  OffsettingAction.swift
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

public protocol OffsettingResponse {
    associatedtype Item

    var items: [Item] { get }
    var offset: Int { get }
    var limit: Int { get }
    var totalItems: Int? { get }
}

extension OffsettingResponse {

    var mayHaveNext: Bool { totalItems.flatMap { offset + limit < $0 }.or(items.count == limit) }
}

public struct RequestOffset: Equatable {
    public let offset: Int
    public let limit: Int

    public init(offset: Int, limit: Int) {
        self.offset = offset
        self.limit = limit
    }
}

public final class OffsettingAction<Input, Response: OffsettingResponse> {

    public typealias Request = (Input, RequestOffset?) -> Observable<Response>

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

    private typealias ActionInput = (Request, Input, RequestOffset?)
    private let action: Action<ActionInput, Response>
    private let actionErrors = PublishRelay<ActionError>()
    private let responses: Observable<(response: Response, type: ActionType)>
    private let nextOffset = BehaviorRelay<RequestOffset?>(value: nil)
    private let actionType = BehaviorRelay<ActionType?>(value: nil)
    private let hasNextRelay = BehaviorRelay<Bool>(value: true)
    private let disposeBag = DisposeBag()

    // MARK: - Init

    public convenience init(limit: Int? = nil, request: @escaping Request) {
        self.init(limit: limit, removeDuplicates: nil, ofType: String.self, request: request)
    }

    public convenience init<S: Hashable>(limit: Int? = nil,
                                         removeDuplicates keyForValue: @escaping ((Response.Item) -> S),
                                         request: @escaping Request) {
        self.init(limit: limit, removeDuplicates: keyForValue, ofType: S.self, request: request)
    }

    private init<S: Hashable>(limit: Int? = nil,
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
            .map { responses in responses.sorted(by: { $0.offset < $1.offset }).flatMap { $0.items } }
            .map { items in keyForValue.flatMap({ items.removeDuplicates(by: $0) }).or(items) }

        configPage()
        configActionType()
        configActionInputs(limit: limit, request: request)
        configActionErrors()
    }

    // MARK: - Private

    private enum ActionType {
        case reload
        case next
    }

    private func configPage() {

        Observable
            .merge(action.elements.map { $0.mayHaveNext ? RequestOffset(offset: $0.offset + $0.limit, limit: $0.limit) : nil },
                   reload.mapTo(nil))
            .bind(to: nextOffset)
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

    private func configActionInputs(limit: Int?, request: @escaping Request) {

        next
            .withLatestFrom(nextOffset) { input, next in next.flatMap { (request, input, $0) } }
            .filterNil()
            .bind(to: action.inputs)
            .disposed(by: disposeBag)

        reload
            .map { input in (request, input, limit.flatMap { RequestOffset(offset: 0, limit: $0) }) }
            .bind(to: action.inputs)
            .disposed(by: disposeBag)
    }

    private func configActionErrors() {

        action.errors
            .bind(to: actionErrors)
            .disposed(by: disposeBag)

        next
            .withLatestFrom(nextOffset)
            .filter { $0 == nil }
            .mapTo(ActionError.notEnabled)
            .bind(to: actionErrors)
            .disposed(by: disposeBag)
    }
}
