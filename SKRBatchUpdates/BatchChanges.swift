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

struct BatchSectionChanges {
    let sectionsToDelete: IndexSet
    let sectionsToInsert: IndexSet
    let sectionMoves: [BatchSectionMove]
}

struct BatchItemChanges {
    let itemsToDelete: [IndexPath]
    let itemsToInsert: [IndexPath]
    let itemMoves: [BatchItemMove]
}

// MARK: - Diffing for hashable items and sections

extension BatchSectionChanges {
    init<SectionType>(from old: [SectionType], to new: [SectionType]) where SectionType: Hashable {
        let (deletes, inserts, moves) = diff(from: old.indexDictionary(), to: new.indexDictionary())
        self.init(sectionsToDelete: IndexSet(deletes),
                  sectionsToInsert: IndexSet(inserts),
                  sectionMoves: moves.map { BatchSectionMove(source: $0, destination: $1) })
    }
}

extension BatchItemChanges {
    init<ItemType>(from old: [[ItemType]], to new: [[ItemType]]) where ItemType: Hashable {
        let (deletes, inserts, moves) = diff(from: old.indexPathDictionary(), to: new.indexPathDictionary())
        self.init(itemsToDelete: deletes,
                  itemsToInsert: inserts,
                  itemMoves: moves.map { BatchItemMove(source: $0, destination: $1) })
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

// MARK: - Applying sections changes to items

extension BatchSectionChanges {
    func apply<ItemType>(to items: [[ItemType]]) -> [[ItemType]] {
        let newCount = items.count + sectionsToInsert.count - sectionsToDelete.count

        let movedIndices = sectionMoves.destinationToSourceDictionary()
        let deletedIndices = Set(sectionsToDelete + sectionMoves.map { $0.source })
        var unchangedIndices = items.indices.lazy.filter({ !deletedIndices.contains($0) }).makeIterator()
        
        return (0..<newCount).map { index in
            if let source = movedIndices[index] {
                return items[source]
            } else if sectionsToInsert.contains(index) {
                return []
            } else {
                guard let oldIndex = unchangedIndices.next() else {
                    fatalError("Mismatching internal state in BatchSectionChanges: \(self)")
                }
                return items[oldIndex]
            }
        }
    }
}

extension Sequence where Iterator.Element == BatchSectionMove {
    func destinationToSourceDictionary() -> [Int: Int] {
        var moves: [Int: Int] = [:]
        for move in self {
            moves[move.destination] = move.source
        }
        return moves
    }
}

// MARK: - Debugging

//extension BatchChanges {
//    func debugPrint() {
//        print("Sections")
//        print(" - Deletes: \(Array<Int>(sectionsToDelete))")
//        print(" - Inserts: \(Array<Int>(sectionsToInsert))")
//        print(" - Moves:   \(sectionMoves)")
//        print("Items")
//        print(" - Deletes: \(itemsToDelete)")
//        print(" - Inserts: \(itemsToInsert)")
//        print(" - Moves:   \(itemMoves)")
//    }
//}

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

