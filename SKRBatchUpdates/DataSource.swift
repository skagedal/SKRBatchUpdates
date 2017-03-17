//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import Foundation

public class DataSource<SectionType: Hashable, ItemType: Hashable> {
    
    public init() {
    }
    
    public var sections: [(SectionType, [ItemType])] = []
    
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
        let (oldSections, oldItems) = unzip(self.sections)
        let (newSections, newItems) = unzip(sections)

        self.sections = sections

        let sectionChanges = BatchSectionChanges(from: oldSections, to: newSections)
        let patchedItems = sectionChanges.apply(to: oldItems)
        let itemChanges = BatchItemChanges(from: patchedItems, to: newItems)
        
        halfTimeItemCounts = patchedItems.map { $0.count }
        tableView.beginUpdates()
        tableView.updateSections(for: sectionChanges, with: animation)
        tableView.endUpdates()
        
        halfTimeItemCounts = nil
        tableView.beginUpdates()
        tableView.updateRows(for: itemChanges, with: animation)
        tableView.endUpdates()
    }
    
    public func animate(to sections: [(SectionType, [ItemType])], in collectionView: UICollectionView, completion: ((Bool) -> Void)? = nil) {
        let (oldSections, oldItems) = unzip(self.sections)
        let (newSections, newItems) = unzip(sections)
        
        self.sections = sections
        
        let sectionChanges = BatchSectionChanges(from: oldSections, to: newSections)
        let patchedItems = sectionChanges.apply(to: oldItems)
        let itemChanges = BatchItemChanges(from: patchedItems, to: newItems)
        
        halfTimeItemCounts = patchedItems.map { $0.count }
        collectionView.performBatchUpdates({
            collectionView.updateSections(for: sectionChanges)
        }, completion: nil)
        
        halfTimeItemCounts = nil
        collectionView.performBatchUpdates({
            collectionView.updateItems(for: itemChanges)
        }, completion: completion)
    }
}

// MARK: - UIKit Extensions

extension UITableView {
    func updateRows(for changes: BatchItemChanges, with animation: UITableViewRowAnimation) {
        deleteRows(at: changes.itemsToDelete, with: animation)
        insertRows(at: changes.itemsToInsert, with: animation)
        for move in changes.itemMoves {
            moveRow(at: move.source, to: move.destination)
        }
    }
    
    func updateSections(for changes: BatchSectionChanges, with animation: UITableViewRowAnimation) {
        deleteSections(changes.sectionsToDelete, with: animation)
        insertSections(changes.sectionsToInsert, with: animation)
        for move in changes.sectionMoves {
            moveSection(move.source, toSection: move.destination)
        }
    }
}

extension UICollectionView {
    func updateItems(for changes: BatchItemChanges) {
        deleteItems(at: changes.itemsToDelete)
        insertItems(at: changes.itemsToInsert)
        for move in changes.itemMoves {
            moveItem(at: move.source, to: move.destination)
        }
    }
    
    func updateSections(for changes: BatchSectionChanges) {
        deleteSections(changes.sectionsToDelete)
        insertSections(changes.sectionsToInsert)
        for move in changes.sectionMoves {
            moveSection(move.source, toSection: move.destination)
        }
    }
}

// MARK: - Helpers

private func unzip<T, U>(_ array: [(T, U)]) -> ([T], [U]) {
    var t: [T] = [], u: [U] = []
    for (a, b) in array {
        t.append(a)
        u.append(b)
    }
    return (t, u)
}

