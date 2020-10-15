//
//  Array+Distinct.swift
//  RxPagination
//
//  Created by Khoi Truong Minh on 10/9/20.
//  Copyright © 2020 Khoi Truong Minh. All rights reserved.
//

import Foundation

extension Array {

    public func removeDuplicates<T: Hashable>(by keyForValue: (Element) -> T) -> Self {
        var currentElements = [T: Bool]()
        var result = Self()
        forEach { element in
            if currentElements[keyForValue(element)] != true {
                result.append(element)
                currentElements[keyForValue(element)] = true
            }
        }
        return result
    }
}
