//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import UIKit

struct BatchSectionMove {
    let source: Int
    let destination: Int
}

struct BatchItemMove {
    let source: IndexPath
    let destination: IndexPath
}

struct BatchChanges {
    let sectionsToDelete: IndexSet
    let sectionsToInsert: IndexSet
    let sectionMoves: [BatchSectionMove]
    
    let itemsToDelete: [IndexPath]
    let itemsToInsert: [IndexPath]
    let itemMoves: [BatchItemMove]
    
    let numberOfItemsInSectionsAfterSectionChanges: [Int]
}

// MARK: - Data source

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

// MARK: - Version with not hashables

extension BatchChanges {
    init<SectionType, ItemType>(from old: [(SectionType, [ItemType])], to new: [(SectionType, [ItemType])], sectionPredicate: (SectionType, SectionType) -> Bool, itemPredicate: (ItemType, ItemType) -> Bool) {
        
        let (oldSections, oldItems) = unzip(old)
        let (newSections, newItems) = unzip(new)
        
        let enumeratedOldSections = oldSections.enumerated().map { ($0, $1) }
        let enumeratedNewSections = newSections.enumerated().map { ($0, $1) }
        let (sectionsToDelete, sectionsToInsert, sectionMoves) = diff(from: enumeratedOldSections, to: enumeratedNewSections, using: sectionPredicate)
        
        let enumeratedOldItems = oldItems.flatIndexPathEnumerated()
        let enumeratedNewItems = newItems.flatIndexPathEnumerated()
        let (itemsToDelete, itemsToInsert, itemMoves) = diff(from: enumeratedOldItems, to: enumeratedNewItems, using: itemPredicate)
        
        self.init(sectionsToDelete: IndexSet(sectionsToDelete),
                  sectionsToInsert: IndexSet(sectionsToInsert),
                  sectionMoves: sectionMoves.map({ BatchSectionMove(source: $0, destination: $1) }),
                  itemsToDelete: itemsToDelete,
                  itemsToInsert: itemsToInsert,
                  itemMoves: itemMoves.map({ BatchItemMove(source: $0, destination: $1) }),
                  numberOfItemsInSectionsAfterSectionChanges: []
                  )
    }
}

private func diff<IndexType, T>(from old: [(IndexType, T)], to new: [(IndexType, T)], using equals: (T, T) -> Bool) -> ([IndexType], [IndexType], [(IndexType, IndexType)]) where IndexType: Equatable {
    var deletes: [IndexType] = []
    var inserts: [IndexType] = []
    var moves: [(IndexType, IndexType)] = []
    
    // Deletes and moves
    for (oldIndex, element) in old {
        if let newIndex = index(of: element, in: new, using: equals) {
            if newIndex != oldIndex {
                moves.append((oldIndex, newIndex))
            }
        } else {
            deletes.append(oldIndex)
        }
    }
    
    // Inserts
    for (newIndex, element) in new {
        if index(of: element, in: old, using: equals) == nil {
            inserts.append(newIndex)
        }
    }
    
    return (deletes, inserts, moves)
}

private func index<IndexType, T>(of item: T, in enumeratedItems:[(IndexType, T)], using equals: (T, T) -> Bool) -> IndexType? {
    if let x = enumeratedItems.first(where: { equals($1, item) }) {
        return x.0
    } else {
        return nil
    }
}

private extension Sequence where Iterator.Element: Sequence {
    /// Flattens a sequence of sequences into a sequence of enums with an `IndexPath` for each element. I.e.:
    ///
    ///    let x = [["a", "b"], ["c"]].flatIndexPathEnumerated()
    ///    // x is [([0, 0], "a"), ([0, 1], "b"), ([1, 0], "c")]
    ///
    /// (Note that `IndexPath`s are expressible as array literals.)
    func flatIndexPathEnumerated() -> [(IndexPath, Iterator.Element.Iterator.Element)] {
        return self.enumerated().flatMap { (section, childSequence) in
            childSequence.enumerated().map { (item, element) in ([section, item], element) }
        }
    }
}

private func unzip<T, U>(_ array: [(T, U)]) -> ([T], [U]) {
    var t: [T] = [], u: [U] = []
    for (a, b) in array {
        t.append(a)
        u.append(b)
    }
    return (t, u)
}

// MARK: - Version that needs Hashable elements

extension BatchChanges {
    init<SectionType, ItemType>(from old: [(SectionType, [ItemType])], to new: [(SectionType, [ItemType])]) where SectionType: Hashable, ItemType: Hashable {
        let (oldSections, oldItems) = unzip(old)
        let (newSections, newItems) = unzip(new)
        
        let oldSectionsDict = oldSections.indexDictionary()
        let newSectionsDict = newSections.indexDictionary()
        let (sectionsToDelete, sectionsToInsert, sectionMoves) = diff(from: oldSectionsDict, to: newSectionsDict)

        let patchedOldItems = applyDiff(to: oldItems, deletes: sectionsToDelete, inserts: sectionsToInsert, moves: sectionMoves)
        let halfTimeRowCounts = patchedOldItems.map { $0.count }
        
        let oldItemsDict = patchedOldItems.indexPathDictionary()
        let newItemsDict = newItems.indexPathDictionary()
        let (itemsToDelete, itemsToInsert, itemMoves) = diff(from: oldItemsDict, to: newItemsDict)
        
        self.init(sectionsToDelete: IndexSet(sectionsToDelete),
                  sectionsToInsert: IndexSet(sectionsToInsert),
                  sectionMoves: sectionMoves.map({ BatchSectionMove(source: $0, destination: $1) }),
                  itemsToDelete: itemsToDelete,
                  itemsToInsert: itemsToInsert,
                  itemMoves: itemMoves.map({ BatchItemMove(source: $0, destination: $1) }),
                  numberOfItemsInSectionsAfterSectionChanges: halfTimeRowCounts
                  )
    }
}

private func diff<ElementType, IndexType>(from old: [ElementType: IndexType], to new: [ElementType: IndexType]) -> ([IndexType], [IndexType], [(IndexType, IndexType)]) where IndexType: Equatable {
    var deletes: [IndexType] = []
    var inserts: [IndexType] = []
    var moves: [(IndexType, IndexType)] = []

    // Deletes and moves
    for (element, oldIndex) in old {
        if let newIndex = new[element] {
            if newIndex != oldIndex {
                moves.append((oldIndex, newIndex))
            }
        } else {
            deletes.append(oldIndex)
        }
    }
    
    // Inserts
    for (element, newIndex) in new {
        if old[element] == nil {
            inserts.append(newIndex)
        }
    }
    
    return (deletes, inserts, moves)
}

func applyDiff<ItemType>(to input: [[ItemType]], deletes sectionsToDelete: [Int], inserts sectionsToInsert: [Int], moves sectionMoves: [(Int, Int)]) -> [[ItemType]] {
    let deletes = Set(sectionsToDelete + sectionMoves.map({ $0.0 }))
    let inserts = Set(sectionsToInsert)
    var moves: [Int: Int] = [:]
    for (source, destination) in sectionMoves {
        moves[destination] = source
    }
    
    var output: [[ItemType]] = []
    for (oldIndex, item) in input.enumerated() {
        let newIndex = output.count
        if let source = moves[newIndex] {
            output.append(input[source])
        } else if inserts.contains(newIndex) {
            output.append([])
        }
        if !deletes.contains(oldIndex) {
            output.append(item)
        }
    }
    while moves[output.count] != nil || inserts.contains(output.count) {
        let newIndex = output.count
        if let source = moves[newIndex] {
            output.append(input[source])
        } else if inserts.contains(newIndex) {
            output.append([])
        }
    }
    return output
}

private extension Sequence where Iterator.Element: Hashable {
    func indexDictionary() -> [Iterator.Element: Int] {
        var dictionary: [Iterator.Element: Int] = [:]
        for (index, element) in self.enumerated() {
            dictionary[element] = index
        }
        return dictionary
    }
}

private extension Sequence where Iterator.Element: Sequence, Iterator.Element.Iterator.Element: Hashable {
    typealias ItemElement = Iterator.Element.Iterator.Element

    func indexPathDictionary() -> [ItemElement: IndexPath] {
        var dictionary: [ItemElement: IndexPath] = [:]
        for (section, items) in self.enumerated() {
            for (item, element) in items.enumerated() {
                dictionary[element] = [section, item]
            }
        }
        return dictionary
    }
}

// MARK: - Debugging

extension BatchChanges {
    func debugPrint() {
        print("Sections")
        print(" - Deletes: \(Array<Int>(sectionsToDelete))")
        print(" - Inserts: \(Array<Int>(sectionsToInsert))")
        print(" - Moves:   \(sectionMoves)")
        print("Items")
        print(" - Deletes: \(itemsToDelete)")
        print(" - Inserts: \(itemsToInsert)")
        print(" - Moves:   \(itemMoves)")
    }
}

extension BatchItemMove: CustomStringConvertible {
    var description: String {
        return "\(source) → \(destination)"
    }
}

extension BatchSectionMove: CustomStringConvertible {
    var description: String {
        return "\(source) → \(destination)"
    }
}

// MARK: - UIKit Extensions

extension UITableView {
    func updateRows(for changes: BatchChanges, with animation: UITableViewRowAnimation) {
        deleteRows(at: changes.itemsToDelete, with: animation)
        insertRows(at: changes.itemsToInsert, with: animation)
        for move in changes.itemMoves {
            moveRow(at: move.source, to: move.destination)
        }
    }
    
    func updateSections(for changes: BatchChanges, with animation: UITableViewRowAnimation) {
        deleteSections(changes.sectionsToDelete, with: animation)
        insertSections(changes.sectionsToInsert, with: animation)
        for move in changes.sectionMoves {
            moveSection(move.source, toSection: move.destination)
        }
    }
    
    func performChanges(_ changes: BatchChanges, with animation: UITableViewRowAnimation) {
        print ("Updating sections...")
        beginUpdates()
        updateSections(for: changes, with: animation)
        endUpdates()
        
        print("Updating rows...")
        beginUpdates()
        updateRows(for: changes, with: animation)
        endUpdates()
    }
}

