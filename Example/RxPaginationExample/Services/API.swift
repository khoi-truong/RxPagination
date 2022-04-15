//
//  API.swift
//  RxPaginationExample
//
//  Created by Khoi Truong Minh on 4/15/22.
//

import Foundation
import Moya
import RxSwift

protocol APIType {

    func request(target: TargetType) -> Single<Response>

    func requestObject<T: Decodable>(target: TargetType, scheduler: SchedulerType) -> Single<T>

    func requestObject<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type
    ) -> Single<T>

    func requestObject<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type,
        atKeyPath keyPath: String?
    ) -> Single<T>

    func requestArray<T: Decodable>(target: TargetType, scheduler: SchedulerType) -> Single<[T]>

    func requestArray<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type
    ) -> Single<[T]>

    func requestArray<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type,
        atKeyPath keyPath: String?
    ) -> Single<[T]>
}

class API: APIType {

    static let `default`: API = { API(provider: APIProvider.default) }()

    // MARK: - Dependencies

    private let provider: MoyaProvider<MultiTarget>

    // MARK: - Init

    init(provider: MoyaProvider<MultiTarget> = APIProvider.default) {
        self.provider = provider
    }

    func request(target: TargetType) -> Single<Response> {
        provider.rx
            .request(MultiTarget(target))
            .filterSuccessfulStatusCodes()
    }

    func requestObject<T: Decodable>(target: TargetType, scheduler: SchedulerType) -> Single<T> {
        self.requestObject(target: target, scheduler: scheduler, type: T.self)
    }

    func requestObject<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type
    ) -> Single<T> {

        self.requestObject(target: target, scheduler: scheduler, type: type, atKeyPath: nil)
    }

    func requestObject<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type,
        atKeyPath keyPath: String?
    ) -> Single<T> {

        self
            .request(target: target)
            .observe(on: scheduler)
            .map(T.self, atKeyPath: keyPath, using: JSONDecoder())
            .observe(on: MainScheduler.instance)
    }

    func requestArray<T: Decodable>(target: TargetType, scheduler: SchedulerType) -> Single<[T]> {
        self.requestArray(target: target, scheduler: scheduler, type: T.self)
    }

    func requestArray<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type
    ) -> Single<[T]> {

        self.requestArray(target: target, scheduler: scheduler, type: type, atKeyPath: nil)
    }

    func requestArray<T: Decodable>(
        target: TargetType,
        scheduler: SchedulerType,
        type: T.Type,
        atKeyPath keyPath: String?
    ) -> Single<[T]> {

        self
            .request(target: target)
            .observe(on: scheduler)
            .map([T].self, atKeyPath: keyPath, using: JSONDecoder())
            .observe(on: MainScheduler.instance)
    }
}

public class APIProvider: MoyaProvider<MultiTarget> {

    static let `default` = APIProvider()

    init(endpointClosure: @escaping EndpointClosure = MoyaProvider<MultiTarget>.defaultEndpointMapping,
         requestClosure: @escaping RequestClosure = MoyaProvider<MultiTarget>.defaultRequestMapping,
         stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
         callbackQueue: DispatchQueue? = nil,
         plugins: [PluginType] = [
            NetworkLoggerPlugin(configuration: .init(logOptions: .formatRequestAscURL))
         ],
         trackInflights: Bool = false,
         allowCache: Bool = true) {

        super.init(endpointClosure: endpointClosure,
                   requestClosure: requestClosure,
                   stubClosure: stubClosure,
                   callbackQueue: callbackQueue,
                   plugins: plugins,
                   trackInflights: trackInflights)
    }
}

extension TargetType {

    var headers: [String: String]? { nil }

    var urlParameters: [String: Any]? { nil }

    var parameterEncoding: ParameterEncoding { JSONEncoding.default }

    var sampleData: Data { Data() }

    var validate: Bool { false }
}
