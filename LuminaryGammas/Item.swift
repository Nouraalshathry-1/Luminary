//
//  Item.swift
//  LuminaryGammas
//
//  Created by Noura Alshathry on 26/05/2026.
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
