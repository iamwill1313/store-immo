//
//  Item.swift
//  StoreImmo
//
//  Created by Rork on April 15, 2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
