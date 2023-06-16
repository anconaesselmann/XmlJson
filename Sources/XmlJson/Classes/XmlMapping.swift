//  Created by Axel Ancona Esselmann on 1/14/18.
//  Copyright © 2018 Axel Ancona Esselmann. All rights reserved.
//

import Foundation

public enum XmlMapping: Hashable {
    
    case array(String, element: String)
    case textNode(String)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .array(let key, element: let element):
            hasher.combine(key)
            hasher.combine(element)
        case .textNode(let key):
            hasher.combine(key)
        }
    }
    
    public static func ==(lhs: XmlMapping, rhs: XmlMapping) -> Bool {
        switch (lhs, rhs) {
        case (.array(let keyLhs, element: let elementLhs),
              .array(let keyRhs, element: let elementRhs)
            ): return keyLhs == keyRhs && elementLhs == elementRhs
        case (.textNode(let keyLhs),
              .textNode(let keyRhs)
            ): return keyLhs == keyRhs
        default: return false
        }
    }
    
}
