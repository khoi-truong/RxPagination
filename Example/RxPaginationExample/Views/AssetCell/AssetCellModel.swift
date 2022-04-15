//
//  AssetCellModel.swift
//  RxPaginationExample
//
//  Created by Khoi Truong Minh on 4/15/22.
//

import Foundation
import Differentiator

struct AssetCellModel: AssetCellModelType, Identifiable, Equatable {
    let id: Int
    let title: String?
    let description: String?
    let imageURL: URL?

    init(asset: Asset) {
        self.id = asset.id
        self.title = (asset.name ?? asset.collection.name).flatMap { "\($0) - \(asset.tokenID)" }
        self.description = asset.description
        self.imageURL = asset.imageURL ?? asset.collection.imageURL ?? asset.creator.imageURL
    }
}

extension AssetCellModel: IdentifiableType {
    var identity: Int { id }
}
