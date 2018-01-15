//  Created by Axel Ancona Esselmann on 1/14/18.
//  Copyright © 2018 Axel Ancona Esselmann. All rights reserved.
//

import Foundation

struct XmlFrame {
    let key: String
    var data: Any
    let mapping: XmlMapping?
    
    init(key: String, data: Any, mapping: XmlMapping? = nil) {
        self.key = key
        self.data = data
        self.mapping = mapping
    }
}
