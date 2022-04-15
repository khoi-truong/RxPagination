//
//  Asset.swift
//  RxPaginationExample
//
//  Created by Khoi Truong Minh on 4/15/22.
//

import Foundation
import RxPagination

struct Asset: Codable, Identifiable, Equatable {
    let id: Int
    let name: String?
    let description: String?
    let imageURL: URL?
    let collection: Collection
    let creator: Creator
    let tokenID: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageURL = "image_url"
        case collection
        case creator
        case tokenID = "token_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.imageURL = (try? container.decodeIfPresent(String.self, forKey: .imageURL)).flatMap(URL.init)
        self.collection = try container.decode(Collection.self, forKey: .collection)
        self.creator = try container.decode(Creator.self, forKey: .creator)
        self.tokenID = try container.decode(String.self, forKey: .tokenID)
    }

    struct Collection: Codable, Equatable {
        let name: String?
        let imageURL: URL?

        enum CodingKeys: String, CodingKey {
            case name
            case imageURL = "image_url"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.imageURL = (try? container.decodeIfPresent(String.self, forKey: .imageURL)).flatMap(URL.init)
        }
    }

    struct Creator: Codable, Equatable {
        let address: String
        let imageURL: URL?

        enum CodingKeys: String, CodingKey {
            case address
            case imageURL = "image_url"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.address = try container.decode(String.self, forKey: .address)
            self.imageURL = (try? container.decodeIfPresent(String.self, forKey: .imageURL)).flatMap(URL.init)
        }
    }
}

struct Assets: Codable, OffsettingResponse {
    let items: [Asset]
    let offset: Int
    let limit: Int
    let totalItems: Int? = nil

    enum CodingKeys: String, CodingKey {
        case items = "assets"
        case offset
        case limit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try container.decodeIfPresent([Asset].self, forKey: .items).orEmpty
        self.offset = try container.decodeIfPresent(Int.self, forKey: .offset).or(0)
        self.limit = try container.decodeIfPresent(Int.self, forKey: .limit).or(5)
    }
}
