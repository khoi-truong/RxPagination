//
//  CursoringAction.swift
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

public protocol CursoringResponse {
    associatedtype Item

    var items: [Item] { get }
    var previous: [String: Any]? { get }
    var next: [String: Any]? { get }
}

public enum RequestCursor {
    case next([String: Any])
    case previous([String: Any])
    case reload(Int?)
}

extension RequestCursor {

    public var urlParameters: [String: Any]? {
        switch self {
        case let .next(info): return info
        case let .previous(info): return info
        case let .reload(limit): return limit.flatMap { ["limit": $0] }
        }
    }
}

public final class CursoringAction<Input, Response: CursoringResponse> {

    public typealias Request = (Input, RequestCursor) -> Observable<Response>

    // MARK: - Inputs

    public let reload: PublishRelay<Input> = PublishRelay<Input>()
    public let next: PublishRelay<Input> = PublishRelay<Input>()
    public let previous: PublishRelay<Input> = PublishRelay<Input>()

    // MARK: - Outputs

    public var errors: Observable<ActionError> { actionErrors.asObservable() }
    public var underlyingError: Observable<Error> { action.underlyingError }
    public var executing: Observable<Bool> { action.executing }
    public let allItems: Observable<[Response.Item]>
    public var items: Observable<[Response.Item]> { responses.map { $0.response.items } }
    public var hasNext: Observable<Bool> { hasNextRelay.asObservable() }
    public var hasPrevious: Observable<Bool> { hasPreviousRelay.asObservable() }
    public var response: Observable<Response?> { mutableResponse.asObservable() }

    // MARK: - Private

    private typealias ActionInput = (Request, Input, RequestCursor)
    private let action: Action<ActionInput, Response>
    private let actionErrors = PublishRelay<ActionError>()
    private let responses: Observable<(response: Response, type: ActionType)>
    private let nextCursor = BehaviorRelay<[String: Any]?>(value: nil)
    private let previousCursor = BehaviorRelay<[String: Any]?>(value: nil)
    private let actionType = BehaviorRelay<ActionType?>(value: nil)
    private let hasNextRelay = BehaviorRelay<Bool>(value: true)
    private let hasPreviousRelay = BehaviorRelay<Bool>(value: false)
    private let mutableResponse = BehaviorRelay<Response?>(value: nil)
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

        self.action = Action<ActionInput, Response> { request, input, cursor in request(input, cursor) }

        self.responses = action.elements
            .withLatestFrom(actionType) { response, type in type.flatMap { (response, $0) } }
            .filterNil()

        self.allItems = responses
            .scan([Response]()) { responses, element in
                switch element.type {
                case .next: return responses + [element.response]
                case .previous: return [element.response] + responses
                case .reload: return [element.response]
                }
            }
            .map { responses in responses.flatMap { $0.items } }
            .map { items in keyForValue.flatMap({ items.removeDuplicates(by: $0) }).or(items) }

        configCursors()
        configActionType()
        configActionInputs(limit: limit, request: request)
        configActionErrors()
    }

    // MARK: - Private

    private enum ActionType {
        case reload
        case next
        case previous
    }

    private func configCursors() {

        Observable
            .merge(action.elements.map { $0.next }, reload.mapTo(nil))
            .bind(to: nextCursor)
            .disposed(by: disposeBag)

        Observable
            .merge(action.elements.map { $0.previous }, reload.mapTo(nil))
            .bind(to: previousCursor)
            .disposed(by: disposeBag)

        Observable
            .merge(action.elements.map { $0.next != nil }, reload.mapTo(true))
            .bind(to: hasNextRelay)
            .disposed(by: disposeBag)

        Observable
            .merge(action.elements.map { $0.previous != nil }, reload.mapTo(false))
            .bind(to: hasPreviousRelay)
            .disposed(by: disposeBag)

        action.elements
            .bind(to: mutableResponse)
            .disposed(by: disposeBag)
    }

    private func configActionType() {

        next
            .withLatestFrom(action.executing)
            .filter(!)
            .mapTo(.next)
            .bind(to: actionType)
            .disposed(by: disposeBag)

        previous
            .withLatestFrom(action.executing)
            .filter(!)
            .mapTo(.previous)
            .bind(to: actionType)
            .disposed(by: disposeBag)

        reload
            .withLatestFrom(action.executing)
            .filter(!)
            .mapTo(.reload)
            .bind(to: actionType)
            .disposed(by: disposeBag)
    }

    private func configActionInputs(limit: Int? = nil, request: @escaping Request) {

        next
            .withLatestFrom(nextCursor) { input, next in next?.replaceEmptyWithNil().flatMap { (input, $0) } }
            .filterNil()
            .map { input, next in (request, input, .next(next)) }
            .bind(to: action.inputs)
            .disposed(by: disposeBag)

        previous
            .withLatestFrom(previousCursor) { input, previous in previous?.replaceEmptyWithNil().flatMap { (input, $0) } }
            .filterNil()
            .map { input, previous in (request, input, .previous(previous)) }
            .bind(to: action.inputs)
            .disposed(by: disposeBag)

        reload
            .map { input in (request, input, .reload(limit)) }
            .bind(to: action.inputs)
            .disposed(by: disposeBag)
    }

    private func configActionErrors() {

        action.errors
            .bind(to: actionErrors)
            .disposed(by: disposeBag)

        next
            .withLatestFrom(nextCursor)
            .filter { $0?.isEmpty != false }
            .mapTo(ActionError.notEnabled)
            .bind(to: actionErrors)
            .disposed(by: disposeBag)

        previous
            .withLatestFrom(previousCursor)
            .filter { $0?.isEmpty != false }
            .mapTo(ActionError.notEnabled)
            .bind(to: actionErrors)
            .disposed(by: disposeBag)
    }
}
