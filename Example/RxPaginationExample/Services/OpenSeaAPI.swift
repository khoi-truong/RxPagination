//
//  OpenSeaAPI.swift
//  RxPaginationExample
//
//  Created by Khoi Truong Minh on 4/15/22.
//

import Alamofire
import Foundation
import Moya
import RxPagination
import RxSwift
import RxSwiftExt

protocol OpenSeaAPITargetType: TargetType {}

extension OpenSeaAPITargetType {

    var baseURL: URL {
        guard let url = URL(string: "https://testnets-api.opensea.io/api/v1") else {
            fatalError("URL is incorrect. Please check again")
        }
        return url
    }
}

enum OpenSeaTarget {

    struct GetAssets: OpenSeaAPITargetType {
        let offset: Int
        let limit: Int

        let path: String = "assets"
        let method: Moya.Method = .get
        var task: Task { .requestParameters(parameters: parameters, encoding: URLEncoding.default) }

        init(next: RequestOffset) {
            self.limit = next.limit
            self.offset = next.offset
        }

        var parameters: [String: Any] {
            var params = [String: Any]()
            params["limit"] = limit
            params["offset"] = offset
            return params
        }
    }
}

protocol OpenSeaAPIType {
    func getAssets(next: RequestOffset) -> Single<Assets>
}

final class OpenSeaAPI: OpenSeaAPIType {

    static let `default`: OpenSeaAPIType = OpenSeaAPI(api: API.default)
    static let apiScheduler = ConcurrentDispatchQueueScheduler(queue: .global())

    private let api: APIType
    private let scheduler: SchedulerType

    init(api: APIType, scheduler: SchedulerType = apiScheduler) {
        self.api = api
        self.scheduler = scheduler
    }

    func getAssets(next: RequestOffset) -> Single<Assets> {
        api
            .requestObject(
                target: OpenSeaTarget.GetAssets(next: next),
                scheduler: scheduler
            )
        }
}
