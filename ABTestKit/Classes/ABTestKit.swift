//
//  ABTestKit.swift
//  ABTestKit
//
//  Created by Yariv Nissim on 7/29/16.
//  Copyright © 2016 ZipRecruiter.com. All rights reserved.
//

import Foundation

/// Use this class to perform A/B tests
/// - note: This class cannot be instantiated in obj-c 
///         however it does support calling several methods such as `runTest:control:test`,
///         `variant:`, `setVariant:for:`, `load`, `save`, `reset` and `migrate:`
@objc public final class ABTestKit: NSObject {
    
    // MARK: Properties
    
    public fileprivate(set) var variants = [Test: Variant]()
    public let configuration: Configuration
    public var variantAllocated: ((_ variant: Variant, _ test: TestName) -> Void)?
    
    // MARK: Initialization
    
    /// Initialize an instance with `Configuration` and call `load`
    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
        load()
    }
    
    /// Initialize an instance with default `Configuration`
    public convenience init(tests: [Test]) { self.init(configuration: Configuration(tests: tests)) }
    /// Initialize an instance with default `Configuration`
    public convenience init(tests: Test...) { self.init(tests: tests) }
    
    deinit {
        save()
    }
    
    // MARK: Variant Allocation
    
    /// Allocate a `Variant` for `Test`
    /// - returns: A random `Variant`
    /// - throws: `TestError.NumberOfVariantsMustBeGreaterThanOne`, `DistributionSumNotEqualToOne`, `InvalidRandomValue` or `InvalidVariantAllocation`.
    /// Also throws errors from `test(for:)`
    fileprivate func allocateVariant(for test: Test) throws -> Variant {
        _ = try self.test(for: test.name)
        
        let distribution: [Percentage]
        switch test.variants {
        case .ab: distribution = [0.5, 0.5]
        case .split(let variants): distribution = Array(repeating: 1/Percentage(variants.count), count: variants.count)
        case .weighted(let variants): distribution = Array(variants.map { $0.1 })
        }
        guard distribution.count > 1 else { throw TestError.numberOfVariantsMustBeGreaterThanOne }
        
        // Check Sum == 1.0
        guard distribution.reduce(0, +) == 1
            else { throw TestError.distributionSumNotEqualToOne }
        
        // Tranform the distribution to a progressive summary where each item is a sum of the previous one
        // [0.1, 0.2, 0.3, 0.4] -> [0.1, 0.3, 0.6, 1.0]
        let progressiveDistribution = distribution.reduce([Percentage]()) { values, current in
            guard let last = values.last else { return [current] }
            return values + [current + last]
        }
        
        // Generate a random number between 0 and 1 (not including 1)
        guard let rand = configuration.randomizer.next(), case 0..<1 = rand
            else { throw TestError.invalidRandomValue }
        
        // find the first variant the random fits in
        guard let indexOfVariant = progressiveDistribution.index(where: { rand < $0 })
            else { throw TestError.invalidVariantAllocation }
        
        return test.variants.names[indexOfVariant]
    }
    
    // MARK: Accessing Tests
    
    /// - returns: `Test` by `name`
    /// - throws: `TestError.InvalidTestName`
    public func test(for name: TestName) throws -> Test {
        guard let index = configuration.tests.index(where: { $0.name == name }) else {
            throw TestError.invalidTestName
        }
        return configuration.tests[index]
    }
    
    // MARK: Accessing Variants
    
    /// Find a `Variant` for `Test` and allocate one if necessary.
    /// - note: `variantAllocated(variant:test:)` handler will be called
    /// - returns: Existing or new `Variant` for `TestName`
    /// - throws: `InvalidTestName` or `InvalidVariantName`
    public func variant(for test: Test) throws -> Variant {
        if let variant = variants[test] { return variant }
        let variant = try allocateVariant(for: test)
        try setVariant(variant, for: test)
        
        return variant
    }
    
    /// Override an existing `Variant` for `Test` or create a new one
    /// - note: `variantAllocated(variant:test:)` handler will be called
    /// - throws: `InvalidTestName` or `InvalidVariantName`
    public func setVariant(_ variant: Variant, for test: Test) throws {
        _ = try self.test(for: test.name)
        
        guard test.variants.names.contains(variant) else {
            throw TestError.invalidVariantName
        }
        variants[test] = variant
        save()
        variantAllocated?(variant, test.name)
    }
    
    /// This method will return `true` if the `variant` is not `control`.
    /// - attention: If there is more than one `test` variant, they all return `true`
    /// - returns: `false` if the `variant` is `control`,
    ///             otherwise `true`
    /// - throws: `InvalidTestName`
    public func isTestVariant(for test: Test) throws -> Bool {
        let aVariant = try variant(for: test)
        
        guard let index = test.variants.names.index(of: aVariant) else {
            return false
        }
        return index != 0 // control is always index 0
    }
    
    // MARK: Running Tests
    
    /// Call the appropriate handler according to the current `Variant` index
    /// - precondition: at least one handler
    /// - attention: This method calls `variantFor(test:)` and will allocate a random variant on first call
    /// - throws: Throws errors from `variant(for:)` and `test(for:)`
    public func runTest(_ test: Test, handlers: [VariantHandler?]) throws {
        assert(handlers.count > 0, "at least one handler is required")
        
        let aVariant = try variant(for: test)
        
        guard let index = test.variants.names.index(of: aVariant), index < handlers.endIndex else { return }
        
        handlers[index]?()
    }
    
    /// Call the appropriate handler according to the current `Variant`
    /// - attention: This method calls `variantFor(test:)` and will allocate a random variant on first call
    /// - throws: `InvalidTestName`
    public func runTest(_ test: Test, control controlHandler: VariantHandler = {}, test testHandler: VariantHandler = {}) throws {
        try isTestVariant(for: test) ? testHandler() : controlHandler()
    }
}

// MARK:- Extensions -

// MARK: <Type Aliases>
public extension ABTestKit {
    public typealias TestName = String
    public typealias Variant = String
    public typealias Percentage = Float
    public typealias VariantHandler = () -> Void
    public typealias PercentageGenerator = AnyIterator<Percentage>
}

// MARK: <ABTestKit.TestError>
public extension ABTestKit {
    public enum TestError: Error {
        case invalidRandomValue
        case distributionSumNotEqualToOne
        case numberOfVariantsMustBeGreaterThanOne
        case invalidVariantAllocation
        case invalidTestName
        case invalidVariantName
    }
}

// MARK: <ABTestKit.Test>
public extension ABTestKit {
    public struct Test {
        public let name: TestName
        public let variants: Variants
        
        public init(name: String, variants: Variants) {
            self.name = name
            self.variants = variants
        }
    }
}

// MARK: <ABTestKit.Configuration>
public extension ABTestKit {
    /// A configuration to instantiate a `ABTestKit` instance
    public struct Configuration {
        public let tests: Set<Test>
        public let userDefaultsKey: String
        fileprivate let randomizer: PercentageGenerator
        
        /// - warning: For Unit Testing purposes
        internal init(tests: [Test], userDefaultsKey key: String? = nil, randomizer: PercentageGenerator? = nil) {
            self.tests = Set(tests)
            self.userDefaultsKey = key ?? "ABTestKit.Variants"
            self.randomizer = randomizer ?? PercentageGenerator { return Percentage(arc4random_uniform(100))/100 }
        }
        
        /// Initialize with a collection of `tests`,
        /// `userDefaultsKey` to be used by `load` and `save` methods for `UserDefaults`
        /// - parameter tests: `Set` of `Test` objects
        /// - parameter userDefaultsKey: key for UserDefaults. defaults to "ABTestKit.Variants"
        public init(tests: Test..., userDefaultsKey key: String? = nil) {
            self.init(tests: tests, userDefaultsKey: key, randomizer: nil)
        }
    }
}

// MARK: <ABTestKit.Variants>
public extension ABTestKit {
    
    /// A type that represents a collection of `variants`
    public enum Variants {
        /// 50/50 split
        ///
        /// - note: `names` will default to `control` and `test`
        case ab
        /// Even split. Each `variant` weight will be equal to `1/variants.count`
        case split([Variant])
        /// A dictionary of `variants` and their appropriate `traffic` in `Percentage`,
        /// e.g. `[control: 0.7, test: 0.3]`
        case weighted([(Variant, Percentage)])
        
        public var names: [String] {
            switch self {
            case .ab: return [Variant.control, Variant.test]
            case .split(let variants): return variants
            case .weighted(let variants): return Array(variants.map { $0.0 })
            }
        }
    }
}

// MARK: <ABTestKit.Variant>
public extension ABTestKit.Variant {
    public static let control = "control"
    public static let test = "test"
}

// MARK: <Persistance>
public extension ABTestKit {
    
    /// Save `Variants` to UserDefaults
    public func save() {
        var plist = [String: String]()
        for (test, variant) in variants {
            plist[test.name] = variant
        }
        UserDefaults.standard.set(plist, forKey: configuration.userDefaultsKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Load `Variants` from UserDefaults
    /// - note: Calling this method will replace the current `variants` with contents of `UserDefaults`
    public func load() {
        guard let plist = UserDefaults.standard.object(forKey: configuration.userDefaultsKey) as? [String: String]
            else { return }
        
        variants = [:]
        for (testName, variant) in plist {
            guard let test = try? test(for: testName), test.variants.names.contains(variant)
                else { continue }
            variants[test] = variant
        }
    }
    
    /// Reset `variants` and clear `UserDefaults`
    public func reset() {
        variants = [:]
        UserDefaults.standard.removeObject(forKey: configuration.userDefaultsKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Migrate data contained in UserDefaults
    /// Load `Variants` from `userDefaultsKey` and save to `configuration.key`
    /// - parameter userDefaultsKey: A custom key to migrate data into a the key defined in `configuration`
    /// - returns: an dictionary of [`test`: `variant`] that could not be migrated or `nil` if no data was found in `UserDefaults`
    /// - attention: Once the migration is complete the previous data will be deleted from `UserDefaults`
    @discardableResult
    public func migrate(from userDefaultsKey: String) -> [String: String]? {
        guard let plist = UserDefaults.standard.object(forKey: userDefaultsKey) as? [String: String]
            else { return nil }
        
        variants = [:]
        var failed = [String: String]()
        for (testName, variant) in plist {
            guard let test = try? test(for: testName), test.variants.names.contains(variant) else {
                failed[testName] = variant; continue
            }
            variants[test] = variant
        }

        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        save()
        
        return failed
    }
}

// MARK: <Computed Properties>
public extension ABTestKit {
    
    /// - returns: Dictionary of Tests and Variants
    @objc(variants) public var variantsByTestName: [TestName: Variant] {
        return self.variants.reduce([TestName: Variant]()) { (variants, current) in
            var copy = variants
            copy[current.0.name] = current.1
            return copy
        }
    }
    
    /// - returns: A list of all Test names
    @objc public var allTests: [String] {
        return configuration.tests.map { $0.name }
    }
    
    /// - returns: A list of Variants and their weights
    @objc public func allVariantsForTest(_ testName: TestName) throws -> [[Variant: Percentage]] {
        let test = try self.test(for: testName)
        switch test.variants {
        case .ab: return [[Variant.control: 0.5], [Variant.test: 0.5]]
        case .weighted(let variants): return variants.map { [$0.0: $0.1] }
        case .split(let variants):
            let percentage = 1/Percentage(variants.count)
            return variants.map { [$0: percentage] }
        }
    }
}

// MARK: <Overloads>
public extension ABTestKit {
    
    /// Overloaded method
    /// - seealso: `variant:` for full description
    @objc(variantForTest:error:)
    public func variant(for testName: TestName) throws -> Variant {
        return try variant(for: test(for: testName))
    }
    
    /// Overloaded method
    /// - seealso: `setVariant:for:` for full description
    @objc(setVariant:forTest:error:)
    public func setVariant(_ variant: Variant, for testName: TestName) throws {
        try! setVariant(variant, for: test(for: testName))
    }
    
    /// Overloaded method
    /// - seealso: `isTestVariant:` for full description
    public func isTestVariant(for testName: TestName) throws -> Bool {
        return try isTestVariant(for: (test(for: testName)))
    }
    
    /// Overloaded method
    /// - seealso: `runTest:control:test:` for full description
    public func runTest(_ name: TestName, control: VariantHandler, test testHandler: VariantHandler) throws {
        try runTest(test(for: name), control: control, test: testHandler)
    }
    
    /// Overloaded method
    /// - seealso: `runTest:handlers:` for full description
    public func runTest(_ name: TestName, handlers: [VariantHandler?]) throws {
        try runTest(test(for: name), handlers: handlers)
    }
    
    /// Overloaded method with a Variadic parameter
    /// - seealso: `runTest:handlers:` for full description
    public func runTest(_ test: Test, handlers: VariantHandler?...) throws {
        try runTest(test, handlers: handlers)
    }
    
    /// Overloaded method
    /// - seealso: `runTest:handlers:` for full description
    public func runTest(_ name: TestName, handlers: VariantHandler?...) throws {
        try runTest(test(for: name), handlers: handlers)
    }
}

// MARK: <Obj-C Wrappers>
public extension ABTestKit {
    
    /// Convenience method
    /// - seealso: `isTestVariant:` for full description
    @objc(isTestVariantForTest:)
    public func isTestVariantNoThrow(for testName: TestName) -> Bool {
        return try! isTestVariant(for: (test(for: testName)))
    }
    
    /// Convenience method
    /// - seealso: `runTest:control:test:` for full description
    @objc(runTest:control:test:)
    public func runTestNoThrow(test name: TestName, control: VariantHandler, test testHandler: VariantHandler) {
        try! runTest(test(for: name), control: control, test: testHandler)
    }
}

// MARK:- <ABTestKit.Test: Hashable>

extension ABTestKit.Test: Hashable {
    public var hashValue: Int { return name.hashValue }
}

public func ==(left: ABTestKit.Test, right: ABTestKit.Test) -> Bool {
    return left.name == right.name
}
