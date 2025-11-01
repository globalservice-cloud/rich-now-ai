//
//  Item.swift
//  RICH Now AI
//
//  Created by Chang Yao tiem on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
