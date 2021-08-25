//  Created by Axel Ancona Esselmann on 1/14/18.
//  Copyright © 2018 Axel Ancona Esselmann. All rights reserved.
//

import Foundation

public enum XmlMapping: Hashable {
    
    case holdsArray(key: String, elementNames: String)
    case isTextNode(key: String)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .holdsArray(key: let key, elementNames: let elementNames):
            hasher.combine(key)
            hasher.combine(elementNames)
        case .isTextNode(key: let key):
            hasher.combine(key)
        }
    }
    
    public static func ==(lhs: XmlMapping, rhs: XmlMapping) -> Bool {
        switch (lhs, rhs) {
        case (.holdsArray(key: let keyLhs, elementNames: let elementNamesLhs),
              .holdsArray(key: let keyRhs, elementNames: let elementNamesRhs)
            ): return keyLhs == keyRhs && elementNamesLhs == elementNamesRhs
        case (.isTextNode(key: let keyLhs),
              .isTextNode(key: let keyRhs)
            ): return keyLhs == keyRhs
        default: return false
        }
    }
    
}
