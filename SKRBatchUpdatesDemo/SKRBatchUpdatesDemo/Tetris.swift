//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import Foundation
import UIKit

let tetrisColumns = 10
let tetrisRows = 20

let validRows = (0..<tetrisRows)
let validColumns = (0..<tetrisColumns)

// MARK: Shapes

enum Tetromino {
    case I
    case J
    case L
    case O
    case S
    case T
    case Z
    
    static let all: [Tetromino] = [.I, .J, .L, .O, .S, .T, .Z]
}

extension Tetromino {
    var template: [[UIColor?]] {
        let __: UIColor? = nil
        
        switch self {
        case .I: return [[__,__,#colorLiteral(red: 0, green: 1, blue: 1, alpha: 1),__],
                         [__,__,#colorLiteral(red: 0, green: 1, blue: 1, alpha: 1),__],
                         [__,__,#colorLiteral(red: 0, green: 1, blue: 1, alpha: 1),__],
                         [__,__,#colorLiteral(red: 0, green: 1, blue: 1, alpha: 1),__]]
            
        case .J: return [[__,#colorLiteral(red: 0, green: 0, blue: 1, alpha: 1),__],
                         [__,#colorLiteral(red: 0, green: 0, blue: 1, alpha: 1),__],
                         [#colorLiteral(red: 0, green: 0, blue: 1, alpha: 1),#colorLiteral(red: 0, green: 0, blue: 1, alpha: 1),__]]
            
        case .L: return [[__,#colorLiteral(red: 1, green: 0.5019607843, blue: 0, alpha: 1),__],
                         [__,#colorLiteral(red: 1, green: 0.5019607843, blue: 0, alpha: 1),__],
                         [__,#colorLiteral(red: 1, green: 0.5019607843, blue: 0, alpha: 1),#colorLiteral(red: 1, green: 0.5019607843, blue: 0, alpha: 1)]]
            
        case .O: return [[#colorLiteral(red: 1, green: 1, blue: 0, alpha: 1),#colorLiteral(red: 1, green: 1, blue: 0, alpha: 1)],
                         [#colorLiteral(red: 1, green: 1, blue: 0, alpha: 1),#colorLiteral(red: 1, green: 1, blue: 0, alpha: 1)]]
            
        case .S: return [[__,#colorLiteral(red: 0.5019607843, green: 1, blue: 0, alpha: 1),__],
                         [__,#colorLiteral(red: 0.5019607843, green: 1, blue: 0, alpha: 1),#colorLiteral(red: 0.5019607843, green: 1, blue: 0, alpha: 1)],
                         [__,__,#colorLiteral(red: 0.5019607843, green: 1, blue: 0, alpha: 1)]]
            
        case .T: return [[__,__,__],
                         [#colorLiteral(red: 0.5019607843, green: 0, blue: 0.5019607843, alpha: 1),#colorLiteral(red: 0.5019607843, green: 0, blue: 0.5019607843, alpha: 1),#colorLiteral(red: 0.5019607843, green: 0, blue: 0.5019607843, alpha: 1)],
                         [__,#colorLiteral(red: 0.5019607843, green: 0, blue: 0.5019607843, alpha: 1),__]]
            
        case .Z: return [[__,#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1),__],
                         [#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1),#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1),__],
                         [#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1),__,__]]
        }
    }
}

func rotatedClockwise<T>(_ array: [[T]]) -> [[T]] {
    let indices = (0..<array.count)
    return indices.map { y in indices.reversed().map { x in array[x][y] } }
}

func rotatedCounterClockwise<T>(_ array: [[T]]) -> [[T]] {
    let indices = (0..<array.count)
    return indices.reversed().map { y in indices.map { x in array[x][y] } }
}

// MARK: Blocks

struct TetrisBlock {
    enum BlockType {
        case empty
        case occupied(UIColor)
    }

    let identifier: Int
    let type: BlockType
}

extension TetrisBlock: Equatable, Hashable {
    static func ==(_ lhs: TetrisBlock, _ rhs: TetrisBlock) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    var hashValue: Int {
        return identifier
    }
}

extension TetrisBlock {
    var isEmpty: Bool {
        if case .empty = self.type {
            return true
        }
        return false
    }
}

// MARK: Rows

struct TetrisRow {
    let identifier: Int
    let blocks: [TetrisBlock]
}

extension TetrisRow: Equatable, Hashable {
    static func ==(_ lhs: TetrisRow, _ rhs: TetrisRow) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    var hashValue: Int {
        return identifier
    }
}

extension TetrisRow {
    func replacingBlock(at index: Int, with block: TetrisBlock) -> TetrisRow {
        var blocks = self.blocks
        blocks[index] = block
        return TetrisRow(identifier: identifier, blocks: blocks)
    }
    
    var hasEmptyBlocks: Bool {
        return blocks.contains(where: { $0.isEmpty })
    }
}

// MARK: Board

struct TetrisBoard {
    let rows: [TetrisRow]
    
    init(rows: [TetrisRow]) {
        self.rows = rows
    }
    
    func isEmpty(_ x: Int, _ y: Int) -> Bool {
        guard validRows.contains(y) && validColumns.contains(x) else {
            return false
        }
        return rows[y].blocks[x].isEmpty
    }
    
    func place(_ shape: [[TetrisBlock?]], x xOffset: Int, y yOffset: Int) -> TetrisBoard? {
        var newRows = rows
        
        for (yShape, shapeBlocks) in shape.enumerated() {
            for (xShape, shapeBlock) in shapeBlocks.enumerated() {
                if let shapeBlock = shapeBlock {
                    let x = xOffset + xShape, y = yOffset + yShape
                    if isEmpty(x, y) {
                        newRows[y] = newRows[y].replacingBlock(at: x, with: shapeBlock)
                    } else {
                        return nil
                    }
                }
            }
        }
        
        return TetrisBoard(rows: newRows)
    }
}

private extension Int {
    func repetitions<T>(_ creator: () -> T) -> [T] {
        return (0..<self).map { _ in creator() }
    }
}

// MARK: Block factory

/// Creates unique blocks and rows by giving them an identifier.
class BlockFactory {
    var identifiers = (0..<Int.max).makeIterator()
    func nextIdentifier() -> Int {
        guard let identifier = identifiers.next() else {
            fatalError("You've played Tetris far too long.")
        }
        return identifier
    }
    
    func emptyBlock() -> TetrisBlock {
        return TetrisBlock(identifier: nextIdentifier(), type: .empty)
    }
    
    func shapeBlock(with color: UIColor) -> TetrisBlock {
        return TetrisBlock(identifier: nextIdentifier(), type: .occupied(color))
    }

    func emptyRow() -> TetrisRow {
        let blocks = tetrisColumns.repetitions(self.emptyBlock)
        return TetrisRow(identifier: nextIdentifier(), blocks: blocks)
    }
    
    func emptyBoard() -> TetrisBoard {
        let rows = tetrisRows.repetitions(self.emptyRow)
        return TetrisBoard(rows: rows)
    }
    
    func shape(from template: [[UIColor?]]) -> [[TetrisBlock?]] {
        return template.map { rows in
            rows.map { color in
                if let color = color {
                    return shapeBlock(with: color)
                } else {
                    return nil
                }
            }
        }
    }
}


// MARK: Game model


class TetrisGame {
    let blockFactory = BlockFactory()
    /// The board except the currently moving tetromino
    var staticBoard: TetrisBoard
    /// The board as it is displayed
    var currentBoard: TetrisBoard

    var currentShape: [[TetrisBlock?]] = []
    var x = 0
    var y = 0
    
    init() {
        staticBoard = blockFactory.emptyBoard()
        currentBoard = staticBoard
    }

    func spawn() -> Bool {
        let tetromino = Tetromino.all.randomPick()

        currentShape = blockFactory.shape(from: tetromino.template)
        x = (tetrisColumns - tetromino.template.count) / 2
        y = 0

        if let board = staticBoard.place(currentShape, x: x, y: y) {
            currentBoard = board
            return true
        }
        return false
    }
    
    func down() -> Bool {
        return tryToPlace(currentShape, x: x, y: y + 1)
    }
    
    func left() -> Bool {
        return tryToPlace(currentShape, x: x - 1, y: y)
    }
    
    func right() -> Bool {
        return tryToPlace(currentShape, x: x + 1, y: y)
    }

    func rotateLeft() -> Bool {
        return tryToPlace(rotatedCounterClockwise(currentShape), x: x, y: y)
    }

    func rotateRight() -> Bool {
        return tryToPlace(rotatedClockwise(currentShape), x: x, y: y)
    }

    func drop() -> Bool {
        if !down() {
            return false
        }
        while (down()) { }
        return true
    }
    
    func fixBlock() {
        guard let board = staticBoard.place(currentShape, x: x, y: y) else {
            fatalError("Current block in a position where it can't be.")
        }
        staticBoard = board
    }
    
    func removeLines() -> Bool {
        let rows = staticBoard.rows.filter { $0.hasEmptyBlocks }
        if rows.count < tetrisRows {
            let newLines = (tetrisRows - rows.count).repetitions(blockFactory.emptyRow)
            staticBoard = TetrisBoard(rows: newLines + rows)
            return true
        }
        return false
    }
    
    func tryToPlace(_ shape: [[TetrisBlock?]], x: Int, y: Int) -> Bool {
        if let board = staticBoard.place(shape, x: x, y: y) {
            currentBoard = board
            currentShape = shape
            self.x = x
            self.y = y
            return true
        }
        return false
    }
}

private extension Array {
    func randomPick() -> Element {
        let index = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}
