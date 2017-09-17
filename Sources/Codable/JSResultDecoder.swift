/**
 *  JavaScriptKit
 *  Copyright (c) 2017 Alexis Aubry. Licensed under the MIT license.
 */

import Foundation

///
/// Decodes JavaScript expression return values to a `Decodable` value.
///

final class JSResultDecoder {

    ///
    /// Decodes a value returned by a JavaScript expression and returns decodes it into the expected
    /// `Decodable` type.
    ///
    /// - parameter value: The value returned by the JavaScript expression.
    /// - returns: The JavaScript text representing the value.
    ///

    func decode<T: Decodable>(_ value: Any) throws -> T {

        //==== I- Serialize the top container ====//

        let container: JSCodingContainer

        if let dictionary = value as? NSDictionary {
            let storage = DictionaryStorage(dictionary)
            container = .keyed(storage)
        } else if let array = value as? NSArray {
            let storage = ArrayStorage(array)
            container = .unkeyed(storage)
        } else {
            let storage = try SingleValueStorage(storedValue: value)
            container = .singleValue(storage)
        }

        //==== II- Decode the container ====//

        let decoder = JSStructureDecoder(container: container)

        if T.self == URL.self || T.self == Date.self {
            let singleValueContainer = try decoder.singleValueContainer()
            return try singleValueContainer.decode(T.self)
        }

        return try T(from: decoder)

    }
    
}

// MARK: - Structure Decoder

///
/// An object that decodes the structure of a JS value.
///

private class JSStructureDecoder: Decoder {

    // MARK: Properties

    /// The decoder's storage.
    var container: JSCodingContainer

    /// The path to the current point in decoding.
    var codingPath: [CodingKey]

    /// Contextual user-provided information for use during decoding.
    var userInfo: [CodingUserInfoKey : Any]

    // MARK: Initilization

    init(container: JSCodingContainer, codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.container = container
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    // MARK: - Containers

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {

        switch container {
        case .keyed(let storage):
            let decodingContainer = JSKeyedDecodingContainer<Key>(referencing: self, storage: storage)
            return KeyedDecodingContainer(decodingContainer)

        default:
            let errorContext = DecodingError.Context(codingPath: codingPath, debugDescription: "Attempt to decode the result using a keyed container container, but the data is encoded as a \(container.debugType) container.")
            throw DecodingError.dataCorrupted(errorContext)
        }

    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {

        switch container {
        case .unkeyed(let storage):
            return JSUnkeyedDecodingContainer(referencing: self, storage: storage)

        default:
            let errorContext = DecodingError.Context(codingPath: codingPath, debugDescription: "Attempt to decode the result using an unkeyed container container, but the data is encoded as a \(container.debugType) container.")
            throw DecodingError.dataCorrupted(errorContext)
        }

    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {

        switch container {
        case .singleValue(let storage):
            return JSSingleValueDecodingContainer(referencing: self, storage: storage, codingPath: codingPath)

        default:
            let errorContext = DecodingError.Context(codingPath: codingPath, debugDescription: "Attempt to decode the result using a single value container, but the data is encoded as a \(container.debugType) container.")
            throw DecodingError.dataCorrupted(errorContext)
        }

    }

}

// MARK: - Single Value Decoder

private class JSSingleValueDecodingContainer: SingleValueDecodingContainer {

    // MARK: Properties

    /// The reference to the decoder we're reading from.
    let decoder: JSStructureDecoder

    /// The container's structure storage.
    let storage: SingleValueStorage

    /// The path to the current point in decoding.
    var codingPath: [CodingKey]

    // MARK: Initialization

    init(referencing decoder: JSStructureDecoder, storage: SingleValueStorage, codingPath: [CodingKey]) {
        self.decoder = decoder
        self.storage = storage
        self.codingPath = codingPath
    }

    // MARK: Decoding

    func decodeNil() -> Bool {
        return decoder.unboxNil(storage)
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try decoder.unboxBool(storage)
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try decoder.unboxInt(storage)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try decoder.unboxInt8(storage)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try decoder.unboxInt16(storage)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try decoder.unboxInt32(storage)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try decoder.unboxInt64(storage)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try decoder.unboxUInt(storage)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try decoder.unboxUInt8(storage)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try decoder.unboxUInt16(storage)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try decoder.unboxUInt32(storage)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try decoder.unboxUInt64(storage)
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try decoder.unboxFloat(storage)
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try decoder.unboxDouble(storage)
    }

    func decode(_ type: String.Type) throws -> String {
        return try decoder.unboxString(storage)
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try decoder.unboxDecodable(storage)
    }

}

// MARK: - Unkeyed Container

///
/// A decoding container for unkeyed storage.
///

private class JSUnkeyedDecodingContainer: UnkeyedDecodingContainer {

    // MARK: Properties

    /// The reference to the parent decoder.
    let decoder: JSStructureDecoder

    /// The array storage we're decoding.
    let storage: ArrayStorage

    // MARK: Unkeyed Container

    /// The path to the current point in decoding.
    var codingPath: [CodingKey]

    /// The number of elements in the container.
    var count: Int? {
        return storage.count
    }

    /// Whether the container has finished decoding elements.
    var isAtEnd: Bool {
        return storage.count == currentIndex
    }

    /// The current index in the container.
    var currentIndex: Int = 0

    // MARK: Initialization

    init(referencing decoder: JSStructureDecoder, storage: ArrayStorage, codingPath: [CodingKey] = []) {
        self.decoder = decoder
        self.storage = storage
        self.codingPath = codingPath
    }

    // MARK: Decoding

    /// Decode the value at the current index.
    func decodeAtCurrentIndex<T>(_ unboxer: (SingleValueStorage) throws -> T) throws -> T {
        guard !self.isAtEnd else { throw indexArrayOutOfBounds }
        let valueStorage = try SingleValueStorage(storedValue: storage[currentIndex])
        currentIndex += 1
        return try unboxer(valueStorage)
    }

    func decodeNil() throws -> Bool {
        return try decodeAtCurrentIndex(decoder.unboxNil)
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try decodeAtCurrentIndex(decoder.unboxBool)
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try decodeAtCurrentIndex(decoder.unboxInt)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try decodeAtCurrentIndex(decoder.unboxInt8)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try decodeAtCurrentIndex(decoder.unboxInt16)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try decodeAtCurrentIndex(decoder.unboxInt32)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try decodeAtCurrentIndex(decoder.unboxInt64)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try decodeAtCurrentIndex(decoder.unboxUInt)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try decodeAtCurrentIndex(decoder.unboxUInt8)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try decodeAtCurrentIndex(decoder.unboxUInt16)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try decodeAtCurrentIndex(decoder.unboxUInt32)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try decodeAtCurrentIndex(decoder.unboxUInt64)
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try decodeAtCurrentIndex(decoder.unboxFloat)
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try decodeAtCurrentIndex(decoder.unboxDouble)
    }

    func decode(_ type: String.Type) throws -> String {
        return try decodeAtCurrentIndex(decoder.unboxString)
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else { throw indexArrayOutOfBounds }

        let value = storage[currentIndex]
        currentIndex += 1

        return try decoder.unboxDecodableValue(value)
    }

    // MARK: Nested Containers

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nestedContainer() -- unkeyed container is at end."))
        }

        guard let value = self.storage[currentIndex] as? NSDictionary else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nestedContainer() -- current value is not a dictionary."))
        }

        currentIndex += 1

        let dictionaryStorage = DictionaryStorage(value)
        let decodingContainer = JSKeyedDecodingContainer<NestedKey>(referencing: decoder, storage: dictionaryStorage, codingPath: codingPath)

        return KeyedDecodingContainer(decodingContainer)

    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nestedUnkeyedContainer() -- unkeyed container is at end."))
        }

        guard let value = self.storage[currentIndex] as? NSArray else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nestedUnkeyedContainer() -- current value is not an array."))
        }

        currentIndex += 1

        let arrayStorage = ArrayStorage(value)
        return JSUnkeyedDecodingContainer(referencing: decoder, storage: arrayStorage, codingPath: codingPath)

    }

    func superDecoder() throws -> Decoder {

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }

        let value = self.storage[currentIndex]
        currentIndex += 1

        let container: JSCodingContainer

        if let dictionary = value as? NSDictionary {
            let storage = DictionaryStorage(dictionary)
            container = .keyed(storage)
        } else if let array = value as? NSArray {
            let storage = ArrayStorage(array)
            container = .unkeyed(storage)
        } else {
            let storage = try SingleValueStorage(storedValue: value)
            container = .singleValue(storage)
        }

        return JSStructureDecoder(container: container, codingPath: decoder.codingPath, userInfo: decoder.userInfo)

    }

    // MARK: Error

    /// The error to throw when
    var indexArrayOutOfBounds: Error {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Index array out of bounds \(currentIndex)")
        return DecodingError.dataCorrupted(context)
    }

}

// MARK: - Keyed Container

///
/// A decoding container for keyed storage.
///

private class JSKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {

    typealias Key = K

    // MARK: Properties

    /// The reference to the parent decoder.
    let decoder: JSStructureDecoder

    /// The array storage we're decoding.
    let storage: DictionaryStorage

    // MARK: Keyed Container

    /// The path to the current point in decoding.
    var codingPath: [CodingKey]

    /// All the keys known by the decoder.
    let allKeys: [K]

    // MARK: Initialization

    init(referencing decoder: JSStructureDecoder, storage: DictionaryStorage, codingPath: [CodingKey] = []) {

        allKeys = storage.dictionary.keys.flatMap { K(stringValue: "\($0.base)") }

        self.decoder = decoder
        self.storage = storage
        self.codingPath = codingPath

    }

    // MARK: Decoding

    /// Decode the value for the given key.
    func decodeValue<T>(forKey key: Key, _ unboxer: (SingleValueStorage) throws -> T) throws -> T {

        guard let value = storage[key.stringValue] else {
            throw DecodingError.valueNotFound(T.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Value for key \(key) not found."))
        }

        let valueStorage = try SingleValueStorage(storedValue: value)
        return try unboxer(valueStorage)

    }

    func contains(_ key: K) -> Bool {
        return allKeys.contains(where: { $0.stringValue == key.stringValue })
    }

    func decodeNil(forKey key: K) throws -> Bool {
        return storage[key.stringValue] == nil
    }

    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try decodeValue(forKey: key, decoder.unboxBool)
    }

    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try decodeValue(forKey: key, decoder.unboxInt)
    }

    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try decodeValue(forKey: key, decoder.unboxInt8)
    }

    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try decodeValue(forKey: key, decoder.unboxInt16)
    }

    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try decodeValue(forKey: key, decoder.unboxInt32)
    }

    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try decodeValue(forKey: key, decoder.unboxInt64)
    }

    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try decodeValue(forKey: key, decoder.unboxUInt)
    }

    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try decodeValue(forKey: key, decoder.unboxUInt8)
    }

    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try decodeValue(forKey: key, decoder.unboxUInt16)
    }

    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try decodeValue(forKey: key, decoder.unboxUInt32)
    }

    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try decodeValue(forKey: key, decoder.unboxUInt64)
    }

    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try decodeValue(forKey: key, decoder.unboxFloat)
    }

    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try decodeValue(forKey: key, decoder.unboxDouble)
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try decodeValue(forKey: key, decoder.unboxString)
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: K) throws -> T {

        guard let value = storage[key.stringValue] else {
            throw DecodingError.valueNotFound(T.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Value for key \(key) not found."))
        }

        return try decoder.unboxDecodableValue(value)

    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {

        guard let value = storage[key.stringValue] as? NSDictionary else {
            throw DecodingError.valueNotFound(NSDictionary.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Could not find a nested keyed container for key \(key)."))
        }

        let dictionaryStorage = DictionaryStorage(value)
        let decodingContainer = JSKeyedDecodingContainer<NestedKey>(referencing: decoder, storage: dictionaryStorage, codingPath: codingPath)

        return KeyedDecodingContainer(decodingContainer)

    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {

        guard let value = storage[key.stringValue] as? NSArray else {
            throw DecodingError.valueNotFound(NSArray.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Could not find a nested unkeyed container for key \(key)."))
        }

        let arrayStorage = ArrayStorage(value)
        return JSUnkeyedDecodingContainer(referencing: decoder, storage: arrayStorage, codingPath: codingPath)

    }

    func superDecoder() throws -> Decoder {

        guard let value = storage[JSONKey.super.stringValue] else {
            throw DecodingError.valueNotFound(NSDictionary.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Could not find a super decoder for key super."))
        }

        let container: JSCodingContainer

        if let dictionary = value as? NSDictionary {
            let storage = DictionaryStorage(dictionary)
            container = .keyed(storage)
        } else if let array = value as? NSArray {
            let storage = ArrayStorage(array)
            container = .unkeyed(storage)
        } else {
            let storage = try SingleValueStorage(storedValue: value)
            container = .singleValue(storage)
        }

        return JSStructureDecoder(container: container, codingPath: decoder.codingPath, userInfo: decoder.userInfo)

    }

    func superDecoder(forKey key: K) throws -> Decoder {

        guard let value = storage[key.stringValue] else {
            throw DecodingError.valueNotFound(NSDictionary.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Could not find a super decoder for key \(key)."))
        }

        let container: JSCodingContainer

        if let dictionary = value as? NSDictionary {
            let storage = DictionaryStorage(dictionary)
            container = .keyed(storage)
        } else if let array = value as? NSArray {
            let storage = ArrayStorage(array)
            container = .unkeyed(storage)
        } else {
            let storage = try SingleValueStorage(storedValue: value)
            container = .singleValue(storage)
        }

        return JSStructureDecoder(container: container, codingPath: decoder.codingPath, userInfo: decoder.userInfo)

    }

}

// MARK: - Unboxing

extension JSStructureDecoder {

    func unboxNil(_ storage: SingleValueStorage) -> Bool {

        switch storage {
        case .null:
            return true
        default:
            return false
        }

    }

    func unboxBool(_ storage: SingleValueStorage) throws -> Bool {

        switch storage {
        case .boolean(let bool):
            return bool
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Bool")
        }

    }

    func unboxInt(_ storage: SingleValueStorage) throws -> Int {

        switch storage {
        case .integer(let integer):
            return integer.intValue
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Int")
        }

    }

    func unboxInt8(_ storage: SingleValueStorage) throws -> Int8 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Int8")
        }

    }

    func unboxInt16(_ storage: SingleValueStorage) throws -> Int16 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Int16")
        }

    }

    func unboxInt32(_ storage: SingleValueStorage) throws -> Int32 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Int32")
        }

    }

    func unboxInt64(_ storage: SingleValueStorage) throws -> Int64 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Int64")
        }

    }

    func unboxUInt(_ storage: SingleValueStorage) throws -> UInt {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "UInt")
        }

    }

    func unboxUInt8(_ storage: SingleValueStorage) throws -> UInt8 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "UInt8")
        }

    }

    func unboxUInt16(_ storage: SingleValueStorage) throws -> UInt16 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "UInt16")
        }

    }

    func unboxUInt32(_ storage: SingleValueStorage) throws -> UInt32 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "UInt32")
        }

    }

    func unboxUInt64(_ storage: SingleValueStorage) throws -> UInt64 {

        switch storage {
        case .integer(let integer):
            return try decodeInteger(integer)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "UInt64")
        }

    }

    func unboxFloat(_ storage: SingleValueStorage) throws -> Float {

        switch storage {
        case .float(let float):
            return float
        case .double(let double):
            return Float(double)
        case .integer(let integer):
            return Float(integer.intValue)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Float")
        }

    }

    func unboxDouble(_ storage: SingleValueStorage) throws -> Double {

        switch storage {
        case .float(let float):
            return Double(float)
        case .double(let double):
            return double
        case .integer(let integer):
            return Double(integer.intValue)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Float")
        }

    }

    func unboxString(_ storage: SingleValueStorage) throws -> String {

        switch storage {
        case .string(let string):
            return string
        default:
            try throwTypeError(storedType: storage.storedType, expected: "String")
        }

    }

    func unboxDate(_ storage: SingleValueStorage) throws -> Date {

        switch storage {
        case .date(let date):
            return date
        case .double(let timeInterval):
            return Date(timeIntervalSince1970: timeInterval / 1000)
        case .float(let timeInterval):
            let timestamp = Double(timeInterval) / 1000
            return Date(timeIntervalSince1970: timestamp)
        case .integer(let anyInterger):
            let timestamp = Double(anyInterger.intValue) / 1000
            return Date(timeIntervalSince1970: timestamp)
        default:
            try throwTypeError(storedType: storage.storedType, expected: "Date")
        }

    }

    func unboxURL(_ storage: SingleValueStorage) throws -> URL {

        switch storage {
        case .string(let string):

            guard let url = URL(string: string) else {
                try throwTypeError(storedType: storage.storedType, expected: "URL")
            }

            return url

        default:
            try throwTypeError(storedType: storage.storedType, expected: "URL")
        }

    }

    func unboxDecodableValue<T: Decodable>(_ value: Any) throws -> T {

        let container: JSCodingContainer

        if let dictionary = value as? NSDictionary {
            let storage = DictionaryStorage(dictionary)
            container = .keyed(storage)
        } else if let array = value as? NSArray {
            let storage = ArrayStorage(array)
            container = .unkeyed(storage)
        } else {
            let storage = try SingleValueStorage(storedValue: value)
            return try unboxDecodable(storage)
        }

        return try unboxDecodable(in: container)

    }

    func unboxDecodable<T: Decodable>(_ storage: SingleValueStorage) throws -> T {

        if T.self == Date.self {
            return try unboxDate(storage) as! T
        } else if T.self == URL.self {
            return try unboxURL(storage) as! T
        }

        return try unboxDecodable(in: .singleValue(storage))

    }

    private func unboxDecodable<T: Decodable>(in container: JSCodingContainer) throws -> T {

        let tempDecoder = JSStructureDecoder(container: container, codingPath: codingPath)
        let decodedObject = try T(from: tempDecoder)

        return decodedObject

    }

    // MARK: Utilities

    /// Fails decoding because of an incompatible type.
    func throwTypeError(storedType: Any.Type, expected: String) throws -> Never {
        let errorContext = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode `\(expected)` because value is of type `\(storedType)`.")
        throw DecodingError.typeMismatch(storedType, errorContext)
    }

    /// Tries to decode a fixed width integer and reports an error on overflow.
    func decodeInteger<T: BinaryInteger & FixedWidthInteger>(_ integer: AnyInteger) throws -> T {

        guard let integer: T = integer.convertingType() else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Integer type `\(T.self)` is too small to store the bits of the decoded value.")
            throw DecodingError.dataCorrupted(context)
        }

        return integer

    }

}
