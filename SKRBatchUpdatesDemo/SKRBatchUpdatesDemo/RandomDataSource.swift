//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import Foundation
import SKRBatchUpdates

enum RandomSection {
    case one
    case two
    case three
    case four
    case five
}

extension RandomSection: CustomStringConvertible {
    var description: String {
        switch self {
        case .one:      return "Section One"
        case .two:      return "Section Two"
        case .three:    return "Section Three"
        case .four:     return "Section Four"
        case .five:     return "Section Five"
        }
    }
}

func randomDataSource() -> [(RandomSection, [String])] {
    var sections: [RandomSection] = [.one, .two, .three, .four, .five]
    var items: [String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"]
    let maxItemsInSection = items.count / sections.count
    
    let numSections = sections.count.random()
    
    return (0..<numSections).map { _ in
        let section = sections.removeRandom()
        let numItems = maxItemsInSection.random()
        let items = (0..<numItems).map({ _ in items.removeRandom() })
        return (section, items)
    }
}

private extension Array {
    mutating func removeRandom() -> Element {
        return remove(at: count.random())
    }
}

private extension Int {
    func random() -> Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}
