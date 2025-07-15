import Foundation

@objc(CalcModuleSwift)
class CalcModuleSwift: NSObject {
    
    @objc
    static func add(a: Double, b: Double) -> NSNumber {
        return NSNumber(value: a + b)
    }
    
    @objc
    static func subtract(a: Double, b: Double) -> NSNumber {
        return NSNumber(value: a - b)
    }
    
    @objc
    static func multiply(a: Double, b: Double) -> NSNumber {
        return NSNumber(value: a * b)
    }
    
    @objc
    static func divide(a: Double, b: Double) -> NSNumber {
        if b == 0 {
            print("CalcModule: Division by zero!")
            return NSNumber(value: Double.nan)
        }
        return NSNumber(value: a / b)
    }
    
    @objc
    static func getConstants() -> NSDictionary {
        return [
            "PI": NSNumber(value: Double.pi),
            "E": NSNumber(value: M_E)
        ]
    }
}