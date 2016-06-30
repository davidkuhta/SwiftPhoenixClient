/*

Converts A class to a dictionary, used for serializing dictionaries to JSON

Supported objects:
- Serializable derived classes
- Arrays of Serializable
- NSData
- String, Numeric, and all other NSJSONSerialization supported objects

*/

import Foundation

public class Serializable : NSObject{
  
  func toDictionary() -> NSDictionary {
    let aClass : AnyClass? = self.dynamicType
    var propertiesCount : CUnsignedInt = 0
    let propertiesInAClass : UnsafeMutablePointer<objc_property_t?>? = class_copyPropertyList(aClass, &propertiesCount)
    let propertiesDictionary : NSMutableDictionary = NSMutableDictionary()
    
    for i in 0 ..< Int(propertiesCount) {
      let property = propertiesInAClass?[i]
      let propName = NSString(cString: property_getName(property), encoding: String.Encoding.utf8.rawValue)
      let propValue : AnyObject! = self.value(forKey: propName! as String);
      
      if propValue is Serializable {
        propertiesDictionary.setValue((propValue as! Serializable).toDictionary(), forKey: (propName as! String))
      } else if propValue is Array<Serializable> {
        var subArray = Array<NSDictionary>()
        for item in (propValue as! Array<Serializable>) {
          subArray.append(item.toDictionary())
        }
        propertiesDictionary.setValue(subArray, forKey: propName! as String)
      } else if propValue is NSData {
        propertiesDictionary.setValue((propValue as! Data).base64EncodedString([]), forKey: propName! as String)
      } else if propValue is Bool {
        propertiesDictionary.setValue((propValue as! Bool).boolValue, forKey: propName! as String)
      } else if propValue is NSDate {
        let date = propValue as! Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "Z"
        let dateString = NSString(format: "/Date(%.0f000%@)/", date.timeIntervalSince1970, dateFormatter.string(from: date))
        propertiesDictionary.setValue(dateString, forKey: propName! as String)
      } else {
        propertiesDictionary.setValue(propValue, forKey: propName! as String)
      }
    }
    
    return propertiesDictionary
  }
  
  func toJson() -> Data! {
    let dictionary = self.toDictionary()
    do {
      return try JSONSerialization.data(withJSONObject: dictionary, options:JSONSerialization.WritingOptions(rawValue: 0))
    } catch _ {
      return nil
    }
  }
  
  public func toJsonString() -> NSString! {
    return NSString(data: self.toJson(), encoding: String.Encoding.utf8.rawValue)
  }
  
  override init() { }
    
    //Per SO how to cast self to unsafe mutable pointer in swift
    func bridge<T : AnyObject>(obj : T) -> UnsafePointer<Void> {
        return UnsafePointer(OpaquePointer(bitPattern: Unmanaged.passUnretained(obj)))
        // return unsafeAddress(of: obj) // ***
    }

    func bridge<T : AnyObject>(ptr : UnsafePointer<Void>) -> T {
        return Unmanaged<T>.fromOpaque(OpaquePointer(ptr)).takeUnretainedValue()
        // return unsafeBitCast(ptr, to: T.self) // ***
    }

    func bridgeRetained<T : AnyObject>(obj : T) -> UnsafePointer<Void> {
        return UnsafePointer(OpaquePointer(bitPattern: Unmanaged.passRetained(obj)))
    }

    func bridgeTransfer<T : AnyObject>(ptr : UnsafePointer<Void>) -> T {
        return Unmanaged<T>.fromOpaque(OpaquePointer(ptr)).takeRetainedValue()
    }
}
