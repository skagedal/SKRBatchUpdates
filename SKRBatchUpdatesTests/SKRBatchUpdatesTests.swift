//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import XCTest
@testable import SKRBatchUpdates

class SKRBatchUpdatesTests: XCTestCase {
    
    func testApplyDiff() {
        
        let sections = [["A"], ["B"]]
        
        let sameSections = applyDiff(to: sections, deletes: [], inserts: [], moves: [])
        assertEqualSections(sections, sameSections)
        
        let deletedFirstSection = applyDiff(to: sections, deletes: [0], inserts: [], moves: [])
        assertEqualSections(deletedFirstSection, [["B"]])
        
        let deletedSecondSection = applyDiff(to: sections, deletes: [1], inserts: [], moves: [])
        assertEqualSections(deletedSecondSection, [["A"]])
        
        let deletedBothSections = applyDiff(to: sections, deletes: [0, 1], inserts: [], moves: [])
        assertEqualSections(deletedBothSections, [])
        
        let insertedSection0 = applyDiff(to: sections, deletes: [], inserts: [0], moves: [])
        assertEqualSections(insertedSection0, [[], ["A"], ["B"]])
        
        let insertedSection1 = applyDiff(to: sections, deletes: [], inserts: [1], moves: [])
        assertEqualSections(insertedSection1, [["A"], [], ["B"]])
        
        let insertedSection2 = applyDiff(to: sections, deletes: [], inserts: [2], moves: [])
        assertEqualSections(insertedSection2, [["A"], ["B"], []])
        
        let deletesAndInserts = applyDiff(to: sections, deletes: [1], inserts: [0,2], moves: [])
        assertEqualSections(deletesAndInserts, [[], ["A"], []])
        
    }
    
}

extension SKRBatchUpdatesTests {
    
    public func assertEqualSections<T>(_ a: [[T]], _ b: [[T]], file: StaticString = #file, line: UInt = #line) where T: Equatable {
        if a != b  {
            XCTFail("arrays not equal", file: file, line: line)
        }
    }
    
}

func ==<Element : Equatable>(lhs: [[Element]], rhs: [[Element]]) -> Bool {
    return lhs.count == rhs.count && !zip(lhs, rhs).contains(where: { $0 != $1 })
}

func !=<Element : Equatable>(lhs: [[Element]], rhs: [[Element]]) -> Bool {
    return !(lhs == rhs)
}
