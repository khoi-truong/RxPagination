//
//  Collection+Empty.swift
//  RxPagination
//
//  Created by Khoi Truong Minh on 10/9/20.
//  Copyright © 2020 Khoi Truong Minh. All rights reserved.
//

import Foundation

public extension Optional where Wrapped: RangeReplaceableCollection {

    var orEmpty: Wrapped {
        guard let value = self else { return Wrapped() }
        return value
    }

    func replaceEmptyWithNil() -> Wrapped? {
        return self.orEmpty.isEmpty ? nil : self
    }
}

public extension Collection {

    func replaceEmpty(with value: Self) -> Self {
        return isEmpty ? value : self
    }

    func replaceEmptyWithNil() -> Self? {
        return self.isEmpty ? nil : self
    }
}
