//
//  ABTestKit_Tests.swift
//  ABTestKitTests
//
//  Created by Yariv Nissim on 7/29/16.
//  Copyright © 2016 ZipRecruiter.com. All rights reserved.
//

import XCTest
@testable import ABTestKit

func sequenceGenerator(_ seq: [Float]) -> ABTestKit.PercentageGenerator {
    return AnyIterator(seq.makeIterator())
}

class ABTestKit_Tests: XCTestCase {
    
    let emptyTestKit = ABTestKit()
    let key = "XCT.ABTestKit.testVariants"
    let migrateKey = "XCT.ABTestKit.testVariants.migrate"
    
    // clear NSUserDefaults
    func reset() {
        emptyTestKit.reset() // reset using the default key
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: migrateKey)
    }
    
    override func setUp() { reset() }
    override func tearDown() { reset() }
    
    // MARK:- A/B allocation
    
    func testABtests() {
        let test1 = ABTestKit.Test(name: "ab_test1", variants: .ab)
        let test2 = ABTestKit.Test(name: "ab_test2", variants: .ab)
        
        let testKit = ABTestKit(tests: test1, test2)
        
        XCTAssertNotNil(try? testKit.test(for: test1.name))
        XCTAssertNotNil(try? testKit.test(for: test2.name))
        
        XCTAssertEqual(try testKit.test(for: test1.name), test1)
        XCTAssertEqual(try testKit.test(for: test2.name), test2)
        
        XCTAssertThrowsError(try testKit.test(for: "unknown test"))
        
        XCTAssertEqual(test1.variants.names.count, 2)
        XCTAssertEqual(test1.variants.names[0], "control")
        XCTAssertEqual(test1.variants.names[1], "test")
    }
    
    func testABvariants() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "ab_test\($0)", variants: .ab)
        }
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 1.0, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.5 = control
        // 0.5..<1 = test
        
        var i = 1
        
        XCTAssertNotNil(try? testKit.test(for: "ab_test\(i)")); i+=1
        XCTAssertNotNil(try? testKit.test(for: "ab_test\(i)")); i+=1
        XCTAssertNotNil(try? testKit.test(for: "ab_test\(i)")); i+=1
        XCTAssertNotNil(try? testKit.test(for: "ab_test\(i)")); i+=1
        
        XCTAssertThrowsError(try testKit.test(for: "unknown test"))
        
        i = 1
        
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "control"); i+=1 // 0.1
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "test"); i+=1 // 0.5
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "control"); i+=1 // 0.3
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "test"); i+=1 // 0.9
        
        XCTAssertThrowsError(try testKit.variant(for: "ab_test\(i)"), "control"); i+=1 // 1.0
        
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "control"); i+=1 // 0.25
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "control"); i+=1 // 0.47
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "test"); i+=1 // 0.99
        XCTAssertEqual(try testKit.variant(for: "ab_test\(i)"), "control"); i+=1 // 0.05
    }
    
    func testABvariantsBool() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "ab_test\($0)", variants: .ab)
        }
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.5 = control
        // 0.5..<1 = test
        
        var i = 1

        XCTAssertFalse(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.1
        XCTAssertTrue(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.5
        XCTAssertFalse(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.3
        XCTAssertTrue(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.9
        XCTAssertFalse(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.25
        XCTAssertFalse(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.47
        XCTAssertTrue(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.99
        XCTAssertFalse(try testKit.isTestVariant(for: "ab_test\(i)")); i+=1 // 0.05
    }
    
    // MARK:- Split tests allocation
    
    func testSplitTests() {
        let tests: [ABTestKit.Test] = (1...5).map {
                ABTestKit.Test(name: "split_test\($0)",
                variants: .split(["control", "test1", "test2"]))
        }
        
        let testKit = ABTestKit(tests: tests)
        
        var i = 1
        
        XCTAssertNotNil(try? testKit.test(for: "split_test\(i)")); i+=1
        XCTAssertNotNil(try? testKit.test(for: "split_test\(i)")); i+=1
        XCTAssertNotNil(try? testKit.test(for: "split_test\(i)")); i+=1
        XCTAssertNotNil(try? testKit.test(for: "split_test\(i)")); i+=1
        
        XCTAssertThrowsError(try testKit.test(for: "unknown test"))
    }
    
    func testSplit_3variants() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "split_test\($0)",
                variants: .split(["control", "test1", "test2"]))
        }
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 1.0, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.33 = control
        // 0.33..<0.66 = test1
        // 0.66..<1.00 = test2
        
        var i = 1
        
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 0.1
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test1"); i+=1 // 0.5
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 0.3
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test2"); i+=1 // 0.9
        
        XCTAssertThrowsError(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 1.0
        
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 0.25
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test1"); i+=1 // 0.47
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test2"); i+=1 // 0.99
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 0.05
        
        XCTAssertEqual(tests[0].variants.names.count, 3)
        XCTAssertEqual(tests[0].variants.names[0], "control")
        XCTAssertEqual(tests[0].variants.names[1], "test1")
        XCTAssertEqual(tests[0].variants.names[2], "test2")
    }
    
    func testSplit_3variantsBool() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "split_test\($0)",
                variants: .split(["control", "test1", "test2"]))
        }
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.33 = control
        // 0.33..<0.66 = test1
        // 0.66..<1.00 = test2
        
        var i = 1
        
        XCTAssertFalse(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.1
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.5
        XCTAssertFalse(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.3
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.9
        XCTAssertFalse(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.25
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.47
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.99
        XCTAssertFalse(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.05
    }
    
    func testSplit_5variants() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "split_test\($0)",
                variants: .split(["control", "test1", "test2", "test3", "test4"]))
        }
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 1.0, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.2 = control
        // 0.2..<0.4 = test1
        // 0.4..<0.6 = test2
        // 0.6..<0.8 = test3
        // 0.6..<1.0 = test4
        
        var i = 1
        
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 0.1
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test2"); i+=1 // 0.5
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test1"); i+=1 // 0.3
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test4"); i+=1 // 0.9
        
        XCTAssertThrowsError(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 1.0
        
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test1"); i+=1 // 0.25
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test2"); i+=1 // 0.47
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "test4"); i+=1 // 0.99
        XCTAssertEqual(try testKit.variant(for: "split_test\(i)"), "control"); i+=1 // 0.05
        
        XCTAssertEqual(tests[0].variants.names.count, 5)
        XCTAssertEqual(tests[0].variants.names[0], "control")
        XCTAssertEqual(tests[0].variants.names[1], "test1")
        XCTAssertEqual(tests[0].variants.names[2], "test2")
        XCTAssertEqual(tests[0].variants.names[3], "test3")
        XCTAssertEqual(tests[0].variants.names[4], "test4")
    }
    
    func testSplit_5variantsBool() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "split_test\($0)",
                variants: .split(["control", "test1", "test2", "test3", "test4"]))
        }
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.2 = control
        // 0.2..<0.4 = test1
        // 0.4..<0.6 = test2
        // 0.6..<0.8 = test3
        // 0.6..<1.0 = test4
        
        var i = 1
        
        XCTAssertFalse(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.1
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.5
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.3
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.9
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.25
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.47
        XCTAssertTrue(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.99
        XCTAssertFalse(try testKit.isTestVariant(for: "split_test\(i)")); i+=1 // 0.05
    }
    
    // MARK:- Weighted tests allocation
    
    func testWeighted_2variants() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "weighted_test\($0)",
                variants: .weighted([("control", 0.3), ("test", 0.7)]))
        }
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 1.0, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.3 = control
        // 0.3..<1 = test
        
        var i = 1
        
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "control"); i+=1 // 0.1
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test"); i+=1 // 0.5
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test"); i+=1 // 0.3
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test"); i+=1 // 0.9
        
        XCTAssertThrowsError(try testKit.variant(for: "weighted_test\(i)"), "control"); i+=1 // 1.0
        
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "control"); i+=1 // 0.25
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test"); i+=1 // 0.47
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test"); i+=1 // 0.99
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "control"); i+=1 // 0.05
        
        XCTAssertEqual(tests[0].variants.names.count, 2)
        XCTAssertEqual(tests[0].variants.names[0], "control")
        XCTAssertEqual(tests[0].variants.names[1], "test")
    }
    
    func testWeighted_2variantsBool() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "weighted_test\($0)",
                variants: .weighted([("control", 0.3), ("test", 0.7)]))
        }
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.3, 0.9, 0.25, 0.47, 0.99, 0.05])))
        
        // 0..<0.3 = control
        // 0.3..<1 = test
        
        var i = 1
        
        XCTAssertFalse(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.1
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.5
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.3
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.9
        XCTAssertFalse(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.25
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.47
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.99
        XCTAssertFalse(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.05
    }
    
    func testWeighted_5variants() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "weighted_test\($0)",
                variants: .weighted([("control", 0.15), ("test1", 0.5), ("test2", 0.1), ("test3", 0.2), ("test4", 0.05)]))
        }
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.73, 0.9, 1.0, 0.25, 0.77, 0.99, 0.05])))
        
        // 0..<0.15 = control
        // 0.15..<0.65 = test1
        // 0.65..<0.75 = test2
        // 0.75..<0.95 = test3
        // 0.95..<1.00 = test4
        
        var i = 1
        
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "control"); i+=1 // 0.1
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test1"); i+=1 // 0.5
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test2"); i+=1 // 0.73
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test3"); i+=1 // 0.9
        
        XCTAssertThrowsError(try testKit.variant(for: "weighted_test\(i)"), "control"); i+=1 // 1.0
        
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test1"); i+=1 // 0.25
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test3"); i+=1 // 0.77
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "test4"); i+=1 // 0.99
        XCTAssertEqual(try testKit.variant(for: "weighted_test\(i)"), "control"); i+=1 // 0.05
        
        XCTAssertEqual(tests[0].variants.names.count, 5)
        XCTAssertEqual(tests[0].variants.names[0], "control")
        XCTAssertEqual(tests[0].variants.names[1], "test1")
        XCTAssertEqual(tests[0].variants.names[2], "test2")
        XCTAssertEqual(tests[0].variants.names[3], "test3")
        XCTAssertEqual(tests[0].variants.names[4], "test4")
    }
    
    func testWeighted_5variantsBool() {
        let tests: [ABTestKit.Test] = (1...10).map {
            ABTestKit.Test(name: "weighted_test\($0)",
                variants: .weighted([("control", 0.15), ("test1", 0.5), ("test2", 0.1), ("test3", 0.2), ("test4", 0.05)]))
        }
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.73, 0.9, 0.25, 0.77, 0.99, 0.05])))
        
        // 0..<0.15 = control
        // 0.15..<0.65 = test1
        // 0.65..<0.75 = test2
        // 0.75..<0.95 = test3
        // 0.95..<1.00 = test4
        
        var i = 1
        
        XCTAssertFalse(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.1
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.5
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.73
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.9
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.25
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.77
        XCTAssertTrue(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.99
        XCTAssertFalse(try testKit.isTestVariant(for: "weighted_test\(i)")); i+=1 // 0.05
    }
    
    func testAllocationClosure() {
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "variant"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("variant", 0.3)]))
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            randomizer: sequenceGenerator([0.1, 0.1, 0.1])))
        
        var count = 0
        testKit.variantAllocated = { variant, test in
            XCTAssertEqual(variant, "control")
            count += 1
            
            switch count {
            case 1: XCTAssertEqual(test, abTest.name)
            case 2: XCTAssertEqual(test, splitTest.name)
            case 3: XCTAssertEqual(test, weightedTest.name)
            default: XCTFail("invalid test")
            }
        }
        
        let _ = try! testKit.variant(for: abTest.name)
        let _ = try! testKit.variant(for: splitTest.name)
        let _ = try! testKit.variant(for: weightedTest.name)
        
        // make sure the closure is only called once per variant
        let _ = try! testKit.variant(for: abTest.name)
        let _ = try! testKit.variant(for: splitTest.name)
        let _ = try! testKit.variant(for: weightedTest.name)
        
        XCTAssertEqual(count, 3)
    }
    
    func testSetVariants() {
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "test"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("test", 0.3)]))
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            randomizer: sequenceGenerator([0.1, 0.1, 0.1])))
        
        // Allocate all variants in control
        XCTAssertEqual(try testKit.variant(for: abTest), "control")
        XCTAssertEqual(try testKit.variant(for: splitTest), "control")
        XCTAssertEqual(try testKit.variant(for: weightedTest), "control")
        
        // Set to `test`
        try! testKit.setVariant("test", for: abTest)
        try! testKit.setVariant("test", for: splitTest)
        try! testKit.setVariant("test", for: weightedTest)
        
        XCTAssertEqual(try testKit.variant(for: abTest), "test")
        XCTAssertEqual(try testKit.variant(for: splitTest), "test")
        XCTAssertEqual(try testKit.variant(for: weightedTest), "test")
    }
    
    // MARK:- Run Tests
    
    func testRunABTests() {
        let test1 = ABTestKit.Test(name: "ab_test1", variants: .ab)
        let test2 = ABTestKit.Test(name: "ab_test2", variants: .ab)
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [test1, test2],
            randomizer: sequenceGenerator([0.1, 0.5])))
        
        // 0..<0.5 = control
        // 0.5..<1 = test
        
        var boolean = false
        
        // control
        try! testKit.runTest(test1
            , control: { boolean = true }
            , test: { XCTFail() }
        )
        XCTAssertTrue(boolean)
        
        boolean = false
        
        try! testKit.runTest(test1, handlers:
            { // control
                boolean = true
            }, { // variant
                XCTFail()
            }, { // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
        
        boolean = false
        
        // test
        try! testKit.runTest(test2
            , control: { XCTFail() }
            , test: { boolean = true }
        )
        XCTAssertTrue(boolean)
        
        boolean = false
        
        try! testKit.runTest(test2, handlers:
            { // control
                XCTFail()
            }, { // variant
                boolean = true
            }, { // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
    }
    
    func testRunSplitTests() {
        let tests: [ABTestKit.Test] = (1...5).map {
            ABTestKit.Test(name: "split_test\($0)",
                variants: .split(["control", "variant_1", "variant_2"]))
        }
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.9])))
        
        // 0..<0.33 = control
        // 0.33..<0.66 = variant_1
        // 0.66..<1.00 = variant_2
        
        var boolean = false
        
        // control
        try! testKit.runTest("split_test1"
            , control: { boolean = true }
            , test: { XCTFail() }
        )
        XCTAssertTrue(boolean)
        
        boolean = false
        
        try! testKit.runTest("split_test1", handlers:
            { // control
                boolean = true
            }, { // variant_1
                XCTFail()
            }, { // variant_2
                XCTFail()
            }, { // invalid variant
                XCTFail()
            }
        )
        
        boolean = false
        
        // variant_1
        try! testKit.runTest("split_test2"
            , control: { XCTFail() }
            , test: { boolean = true }
        )
        XCTAssertTrue(boolean)
        
        boolean = false
        
        try! testKit.runTest("split_test2", handlers:
            { // control
                XCTFail()
            }, { // variant_1
                boolean = true
            }, { // variant_2
                XCTFail()
            }, { // invalid variant
                XCTFail()
            }
        )

        boolean = false
        
        // variant_2
        try! testKit.runTest("split_test3"
            , control: { XCTFail() }
            , test: { boolean = true }
        )
        XCTAssertTrue(boolean)
        
        boolean = false
        
        try! testKit.runTest("split_test3", handlers:
            { // control
                XCTFail()
            }, { // variant_1
                XCTFail()
            }, { // variant_2
                boolean = true
            }, { // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
    }
    
    func testRunWeightedTests() {
        let tests: [ABTestKit.Test] = (1...5).map {
            ABTestKit.Test(name: "weighted_test\($0)",
                variants: .weighted([("control", 0.15), ("variant_1", 0.5), ("variant_2", 0.1), ("variant_3", 0.2), ("variant_4", 0.05)]))
        }
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: tests, randomizer: sequenceGenerator([0.1, 0.5, 0.73, 0.9, 0.99])))
        
        // 0..<0.15 = control
        // 0.15..<0.65 = variant_1
        // 0.65..<0.75 = variant_2
        // 0.75..<0.95 = variant_3
        // 0.95..<1.00 = variant_4
        
        var boolean = false
        
        // control
        try! testKit.runTest("weighted_test1", handlers:
            {
                // control
                boolean = true
            }, {
                // variant_1
                XCTFail()
            }, {
                // variant_2
                XCTFail()
            }, {
                // variant_3
                XCTFail()
            }, {
                // variant_4
                XCTFail()
            }, {
                // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
        boolean = false
        
        // variant_1
        try! testKit.runTest("weighted_test2", handlers:
            {
                // control
                XCTFail()
            }, {
                // variant_1
                boolean = true
            }, {
                // variant_2
                XCTFail()
            }, {
                // variant_3
                XCTFail()
            }, {
                // variant_4
                XCTFail()
            }, {
                // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
        boolean = false
        
        // variant_2
        try! testKit.runTest("weighted_test3", handlers:
            {
                // control
                XCTFail()
            }, {
                // variant_1
                XCTFail()
            }, {
                // variant_2
                boolean = true
            }, {
                // variant_3
                XCTFail()
            }, {
                // variant_4
                XCTFail()
            }, {
                // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
        boolean = false
        
        // variant_3
        try! testKit.runTest("weighted_test4", handlers:
            {
                // control
                XCTFail()
            }, {
                // variant_1
                XCTFail()
            }, {
                // variant_2
                XCTFail()
            }, {
                // variant_3
                boolean = true
            }, {
                // variant_4
                XCTFail()
            }, {
                // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
        boolean = false
        
        // variant_4
        try! testKit.runTest("weighted_test5", handlers:
            {
                // control
                XCTFail()
            }, {
                // variant_1
                XCTFail()
            }, {
                // variant_2
                XCTFail()
            }, {
                // variant_3
                XCTFail()
            }, {
                // variant_4
                boolean = true
            }, {
                // invalid variant
                XCTFail()
            }
        )
        XCTAssertTrue(boolean)
    }
    
    // MARK:- Errors
    
    func testInvalidRandomValue() {
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "variant1"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("variant1", 0.3)]))
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            randomizer: sequenceGenerator([1.0, -1.0])))
        
        // A/B: 1.0
        XCTAssertThrowsError(try testKit.variant(for: abTest.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.invalidRandomValue)
        }
        
        // Split: -1.0
        XCTAssertThrowsError(try testKit.variant(for: splitTest.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.invalidRandomValue)
        }
        
        // Weighted: nil
        XCTAssertThrowsError(try testKit.variant(for: weightedTest.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.invalidRandomValue)
        }
    }
    
    func testDistributionSumNotEqualToOne() {
        let test1 = ABTestKit.Test(name: "test1", variants: .weighted([("control", 0.7), ("variant1", 0.1)]))
        let test2 = ABTestKit.Test(name: "test2", variants: .weighted([("control", 0.7), ("variant1", 0.1), ("variant2", 0.3)]))
        let test3 = ABTestKit.Test(name: "test3", variants: .weighted([("control", 0.999), ("variant1", 0)]))
        let testKit = ABTestKit(tests: test1, test2, test3)
        
        XCTAssertThrowsError(try testKit.variant(for: test1.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.distributionSumNotEqualToOne)
        }
        
        XCTAssertThrowsError(try testKit.variant(for: test2.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.distributionSumNotEqualToOne)
        }
        
        XCTAssertThrowsError(try testKit.variant(for: test3.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.distributionSumNotEqualToOne)
        }
    }
    
    func testNumberOfVariantsMustBeGreaterThanOne() {
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7)]))
        
        let testKit = ABTestKit(tests: splitTest, weightedTest)
        
        // Split
        XCTAssertThrowsError(try testKit.variant(for: splitTest.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.numberOfVariantsMustBeGreaterThanOne)
        }
        
        // Weighted
        XCTAssertThrowsError(try testKit.variant(for: weightedTest.name)) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.numberOfVariantsMustBeGreaterThanOne)
        }
    }
    
    func testInvalidTestName() {
        let test = ABTestKit.Test(name: "ab_test", variants: .ab)
        let testKit = ABTestKit(tests: test)
        
        XCTAssertThrowsError(try testKit.variant(for: "unknown_name")) { error in
            guard let error = error as? ABTestKit.TestError else {
                XCTFail("wrong error type"); return
            }
            XCTAssertEqual(error, ABTestKit.TestError.invalidTestName)
        }
    }
    
    func testInvalidVariantAllocation() {
        // This error is impossible to reproduce since the previous checks guarantee it'll be never thrown
        XCTAssertTrue(true)
    }
    
    // MARK:- Persistance
    
    func testSave() {
        // Make sure we're starting fresh
        XCTAssertNil(UserDefaults.standard.object(forKey: key))
        
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "variant"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("variant", 0.3)]))
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            userDefaultsKey: key,
            randomizer: sequenceGenerator([0.1, 0.1, 0.1])))
        
        // Allocate all variants in control
        XCTAssertEqual(try testKit.variant(for: abTest.name), "control")
        XCTAssertEqual(try testKit.variant(for: splitTest.name), "control")
        XCTAssertEqual(try testKit.variant(for: weightedTest.name), "control")
        
        testKit.save()
        
        let data = UserDefaults.standard.object(forKey: key)
        XCTAssertNotNil(data)
        
        let dictionary = data as? [String: String]
        XCTAssertNotNil(dictionary)
        
        let abTestVariant = dictionary?[abTest.name]
        XCTAssertNotNil(abTestVariant)
        XCTAssertEqual(abTestVariant, "control")
        
        let splitTestVariant = dictionary?[splitTest.name]
        XCTAssertNotNil(splitTestVariant)
        XCTAssertEqual(splitTestVariant, "control")
        
        let weightedTestVariant = dictionary?[splitTest.name]
        XCTAssertNotNil(weightedTestVariant)
        XCTAssertEqual(weightedTestVariant, "control")
    }
    
    func testLoad() {
        // Make sure we're starting fresh
        XCTAssertNil(UserDefaults.standard.object(forKey: key))
        
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "test"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("test", 0.3)]))
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            userDefaultsKey: key,
            randomizer: sequenceGenerator([0.1, 0.1, 0.1])))
        
        // Inject data to load
        UserDefaults.standard.set([abTest.name: "test", splitTest.name: "test", weightedTest.name: "test"], forKey: key)
        
        testKit.load()
        
        XCTAssertEqual(testKit.variants.count, 3)
        XCTAssertEqual(try testKit.variant(for: abTest.name), "test")
        XCTAssertEqual(try testKit.variant(for: splitTest.name), "test")
        XCTAssertEqual(try testKit.variant(for: weightedTest.name), "test")
    }
    
    func testMigrateAll() {
        // Make sure we're starting fresh
        XCTAssertNil(UserDefaults.standard.object(forKey: key))
        XCTAssertNil(UserDefaults.standard.object(forKey: migrateKey))
        
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "test"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("test", 0.3)]))
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            userDefaultsKey: key,
            randomizer: sequenceGenerator([0.1, 0.1, 0.1])))
        
        // Inject data to migrate
        UserDefaults.standard.set([abTest.name: "test", splitTest.name: "test", weightedTest.name: "test"], forKey: migrateKey)
        
        _ = testKit.migrate(from: migrateKey)
        
        XCTAssertEqual(testKit.variants.count, 3)
        XCTAssertEqual(try testKit.variant(for: abTest.name), "test")
        XCTAssertEqual(try testKit.variant(for: splitTest.name), "test")
        XCTAssertEqual(try testKit.variant(for: weightedTest.name), "test")
    }
    
    func testMigratePartial() {
        // Make sure we're starting fresh
        XCTAssertNil(UserDefaults.standard.object(forKey: key))
        XCTAssertNil(UserDefaults.standard.object(forKey: migrateKey))
        
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "test"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("test", 0.3)]))
        let unknownTest = ABTestKit.Test(name: "unknown", variants: .ab)
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            userDefaultsKey: key,
            randomizer: sequenceGenerator([0.1, 0.1, 0.1])))
        
        // Inject data to migrate
        UserDefaults.standard.set([abTest.name: "test", splitTest.name: "test", weightedTest.name: "test", unknownTest.name: "control"], forKey: migrateKey)
        
        let rejected = testKit.migrate(from: migrateKey)
        XCTAssertNotNil(rejected)
        XCTAssertEqual(rejected?.count, 1)
        XCTAssertNotNil(rejected?[unknownTest.name])
        XCTAssertEqual(rejected?[unknownTest.name], "control")
        
        XCTAssertEqual(testKit.variants.count, 3)
        XCTAssertEqual(try testKit.variant(for: abTest.name), "test")
        XCTAssertEqual(try testKit.variant(for: splitTest.name), "test")
        XCTAssertEqual(try testKit.variant(for: weightedTest.name), "test")
    }
    
    func testMigrateNone() {
        // Make sure we're starting fresh
        XCTAssertNil(UserDefaults.standard.object(forKey: key))
        XCTAssertNil(UserDefaults.standard.object(forKey: migrateKey))
        
        let abTest = ABTestKit.Test(name: "ab_test", variants: .ab)
        let splitTest = ABTestKit.Test(name: "split_test", variants: .split(["control", "test"]))
        let weightedTest = ABTestKit.Test(name: "weighted_test", variants: .weighted([("control", 0.7), ("test", 0.3)]))
        
        let testKit = ABTestKit(configuration: ABTestKit.Configuration(
            tests: [abTest, splitTest, weightedTest],
            userDefaultsKey: key,
            randomizer: sequenceGenerator([0.1, 0.1, 0.1])))
        
        let rejected = testKit.migrate(from: migrateKey)
        XCTAssertNil(rejected)
        XCTAssertEqual(testKit.variants.count, 0)
    }
}
