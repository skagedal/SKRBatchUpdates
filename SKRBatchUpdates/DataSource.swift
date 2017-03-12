//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import Foundation

public class DataSource<SectionType: Hashable, ItemType: Hashable> {
    
    public init() {
    }
    
    var sections: [(SectionType, [ItemType])] = []
    
    var halfTimeItemCounts: [Int]? = nil
    
    public func numberOfSections() -> Int {
        if let rowCounts = halfTimeItemCounts {
            return rowCounts.count
        } else {
            return sections.count
        }
    }
    
    public func numberOfRows(in section: Int) -> Int {
        if let rowCounts = halfTimeItemCounts {
            return rowCounts[section]
        } else {
            let (_, items) = sections[section]
            return items.count
        }
    }
    
    public func section(at sectionIndex: Int) -> SectionType {
        let (section, _) = sections[sectionIndex]
        return section
    }
    
    public func itemForRow(at indexPath: IndexPath) -> ItemType {
        guard halfTimeItemCounts == nil else {
            fatalError("Cells are expected to not be accessed in this state")
        }
        let (_, items) = sections[indexPath.section]
        return items[indexPath.item]
    }
    
    public func animate(to sections: [(SectionType, [ItemType])], in tableView: UITableView, with animation: UITableViewRowAnimation) {
        let changes = BatchChanges(from: self.sections, to: sections)
        self.sections = sections
        
        halfTimeItemCounts = changes.numberOfItemsInSectionsAfterSectionChanges
        tableView.beginUpdates()
        tableView.updateSections(for: changes, with: animation)
        tableView.endUpdates()
        
        halfTimeItemCounts = nil
        tableView.beginUpdates()
        tableView.updateRows(for: changes, with: animation)
        tableView.endUpdates()
    }
}

