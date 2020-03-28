//
//  ParsingTests.swift
//  relaycontroller
//
//  Created by Van Simmons on 3/28/20.
//

import XCTest
@testable import Server

class ParsingTests: XCTestCase {
    static var subject1 = "sat/+/fx/+"
    static var subject2 = "#"
    static var subject3 = "sat/+/#"
    static var subject4 = "sat/+/fx/#"
    
    static var test1 = "sat/ABCD1234/fx/sound"
    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParsingTopic() throws {
        
    }
}
