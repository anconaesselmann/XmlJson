//  Created by Axel Ancona Esselmann on 1/14/18.
//  Copyright © 2018 Axel Ancona Esselmann. All rights reserved.
//

import Foundation

public struct XmlTransformation: Hashable {

    public typealias Mapping = (Any) -> Any

    let key: String
    let map: Mapping
    
    public init(key: String, map: @escaping Mapping) {
        self.key = key
        self.map = map
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    public static func ==(lhs: XmlTransformation, rhs: XmlTransformation) -> Bool {
        lhs.key == rhs.key
    }

    public static func double(_ key: String) -> Self {
        .init(key: key) { Double($0 as? String ?? "0") ?? 0 }
    }

    public static func int(_ key: String) -> Self {
        .init(key: key) { Int($0 as? String ?? "0") ?? 0 }
    }

    public static func bool(_ key: String) -> Self {
        .init(key: key) { Bool(($0 as? String)?.lowercased() ?? "false") ?? false }
    }

    public static func dateStringToUnixSeconds(_ key: String, format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Self {
        .init(key: key) { (date(from: $0 as? String ?? "", format: format) ?? Date()).timeIntervalSince1970 }
    }

    public static func transfrom(_ key: String, using mapping: @escaping Mapping) -> Self {
        .init(key: key, map: mapping)
    }

    private static let dateFormatter = DateFormatter()

    private static func date(from string: String, format: String) -> Date? {
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: string)
    }
}

