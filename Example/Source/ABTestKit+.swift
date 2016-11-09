//
//  ABTestKit+.swift
//  Job Search
//
//  Created by Yariv Nissim on 8/3/16.
//  Copyright © 2016 ZipRecruiter.com. All rights reserved.
//

import Foundation
import ABTestKit

// Create the various A/B Tests with their names, variants and weights
extension ABTestKit.Test {
    static let featureNumberOne = ABTestKit.Test(name: "feature_1", date: "010101") // 50-50 split
    static let featureNumberTwo = ABTestKit.Test(name: "feature_2", date: "030202", variants: .split([.control, .test, "test2", "test3"])) // even split - 25% each
    static let featureNumberThree = ABTestKit.Test(name: "feature_3", date: "030303", variants: .weighted([(.control, 0.9), (.test, 0.1)])) // 90-10 split
    
    // Convenience initializer to append date to the test name with a default variant
    init(name: String, date: String, variants: ABTestKit.Variants = .ab) {
        let formattedName = "\(date)_\(name)"
        self.init(name: formattedName, variants: variants)
    }
}

// Create a `shared` property inside. Don't forget to initialize with all the *active* tests
extension ABTestKit {
    static let shared: ABTestKit = {
        let testKit = ABTestKit(tests:
            .featureNumberOne, .featureNumberTwo, .featureNumberThree
        );
        testKit.migrate(from: "PreviousABTestValues")
        
        testKit.variantAllocated = { variant, test in
            // Make API call to update the server, report an event, print log, etc.
        }
        return testKit
    }()
}

// Expose Test Names to Obj-C when necessary
extension ABTestKit {
    static var featureNumberOne: TestName { return Test.featureNumberOne.name }
    static var featureNumberTwo: TestName { return Test.featureNumberTwo.name }
    static var featureNumberThree: TestName { return Test.featureNumberThree.name }
}
