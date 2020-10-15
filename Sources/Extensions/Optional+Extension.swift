//
//  Optional+Extension.swift
//  RxPagination
//
//  Created by Khoi Truong Minh on 10/9/20.
//  Copyright © 2020 Khoi Truong Minh. All rights reserved.
//

import Foundation
import RxOptional

public extension Optional {

    func `or`(_ value: Wrapped?) -> Optional {
        return self ?? value
    }

    func `or`(_ value: Wrapped) -> Wrapped {
        return self ?? value
    }
}
