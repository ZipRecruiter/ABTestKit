# ABTestKit

[![CI Status](http://img.shields.io/travis/Yariv Nissim/ABTestKit.svg?style=flat)](https://travis-ci.org/Yariv Nissim/ABTestKit)
[![Version](https://img.shields.io/cocoapods/v/ABTestKit.svg?style=flat)](http://cocoapods.org/pods/ABTestKit)
[![License](https://img.shields.io/cocoapods/l/ABTestKit.svg?style=flat)](http://cocoapods.org/pods/ABTestKit)
[![Platform](https://img.shields.io/cocoapods/p/ABTestKit.svg?style=flat)](http://cocoapods.org/pods/ABTestKit)

## Installation

### Cocoapods

```ruby
use_frameworks!
pod "ABTestKit"
```

### Manual

Copy `ABTestKit.swift` file to your project.

## Setup

Copy `ABTestKit+.swift` found in the Example project and define your tests inside the extension to `ABTestKit.Test` struct.  
An A/B Test is initialized with a name and variants using an enum with the following options:  
- `ab`: control and test variant with 50% weight each
- `split`: n number of variants where weight for each equals `1÷n`  
- `weighted`: custom defined weights

_Optionally add a convenience initializer to add defaults values, formatting, etc._

```swift
extension ABTestKit.Test {
    static let featureNumberOne = ABTestKit.Test(name: "feature_1", date: "010101") // 50-50 split
    static let featureNumberTwo = ABTestKit.Test(name: "feature_2", date: "030202", variants: .split([.control, .test, "test2", "test3"])) // even 25% each
    static let featureNumberThree = ABTestKit.Test(name: "feature_3", date: "030303", variants: .weighted([(.control, 0.9), (.test, 0.1)])) // 90-10 split
    
    // Convenience initializer
    init(name: String, date: String, variants: ABTestKit.Variants = .ab) {
        let formattedName = "\(date)_\(name)"
        self.init(name: formattedName, variants: variants)
    }
}
```

Use the `shared` singleton property to setup the framework:

- Enable all the active tests

- React to bucketing events (optional)

- Migrate the buckets in UserDefaults to the key defined in the `Configuration` object (optional)

```swift
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
```

Optional: Expose the tests to Objective-C by returning their name, since Obj-C can't see the `Test` struct.

```swift
extension ABTestKit {
    static var featureNumberOne: TestName { return Test.featureNumberOne.name }
    static var featureNumberTwo: TestName { return Test.featureNumberTwo.name }
    static var featureNumberThree: TestName { return Test.featureNumberThree.name }
}
```

## Usage

### Perform logic based on buckets

```swift
try! ABTestKit.shared.runTest(.featureNumberOne
    , control: {
        performSegue(withIdentifier: "control", sender: self)
}
    , test: {
        performSegue(withIdentifier: "test", sender: self)
})

// Trailing closure will default to `test`
try! ABTestKit.shared.runTest(.featureNumberOne) {
        performSegue(withIdentifier: "test", sender: self)
}
```

### Multiple test buckets

```swift
try! ABTestKit.shared.runTest(.featureNumberTwo, handlers: {
    // control
    view.backgroundColor = .white
}, {
    // test
    view.backgroundColor = .red
}, {
    // test2
    view.backgroundColor = .green
}, {
    // test3
    view.backgroundColor = .blue
})
```

### Hide (or show) views

```swift
button.isHidden = try! ABTestKit.shared.isTestVariant(for: .featureNumberThree)
```

### Control flow

```swift
guard try! ABTestKit.shared.isTestVariant(for: .featureNumberThree) else { return }
```

### Exclude control bucket

```swift
if try! ABTestKit.shared.isTestVariant(for: .featureNumberTwo) {
    // Any test bucket
    print("Not control bucket")
}
```

## Advanced

### Initialize with custom configuration

```swift
let configuration = ABTestKit.Configuration(tests: .featureNumberOne, .featureNumberTwo, .featureNumberThree,
                                            userDefaultsKey: "com.acme.ABTests")
let testKit = ABTestKit(configuration: configuration)
```

### Override buckets

```swift
try! ABTestKit.shared.setVariant(.control, for: .featureNumberOne)
```

### Reset all buckets

```swift
ABTestKit.shared.reset()
```

### Access all active tests

```swift
print(ABTestKit.shared.allTests) // ["feature_1", "feature_2", "feature_3"]
```

### Access the selected buckets for tests

```swift
print(ABTestKit.shared.variantsByTestName) // [["feature_1: "control"], ["feature_2": "test2"], ["feature_3: "test"]]
```

## Author

[Yariv Nissim](mailto:yariv@ziprecruiter.com) | [yar1vn](http://twitter.com/yar1vn)  
[ZipRecruiter.com](http://www.ziprecruiter.com)  
