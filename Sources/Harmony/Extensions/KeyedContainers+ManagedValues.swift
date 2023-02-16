//
//  KeyedContainers+ManagedValues.swift
//  Harmony
//
//  Created by Riley Testut on 10/25/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

private struct AnyNSCodable: Codable {
    var value: NSCoding

    init(value: NSCoding) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let data = try container.decode(Data.self)

        if let value = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSCoding {
            self.value = value
        } else {
            throw DecodingError.typeMismatch(NSCoding.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Value does not conform to NSCoding."))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
        try container.encode(data)
    }
}

extension KeyedDecodingContainer {
    func decodeManagedValue(forKey key: Key, entity: NSEntityDescription) throws -> Any? {
        guard let attribute = entity.attributesByName[key.stringValue]
        else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Managed object's property \(key.stringValue) could not be found.")
        }

        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
            let value = attribute.isOptional ? try decodeIfPresent(type, forKey: key) : try self.decode(type, forKey: key)
            return value
        }

        let value: Any?

        switch attribute.attributeType {
        case .integer16AttributeType: value = try decode(Int16.self, forKey: key)
        case .integer32AttributeType: value = try decode(Int32.self, forKey: key)
        case .integer64AttributeType: value = try decode(Int64.self, forKey: key)
        case .decimalAttributeType: value = try decode(Decimal.self, forKey: key)
        case .doubleAttributeType: value = try decode(Double.self, forKey: key)
        case .floatAttributeType: value = try decode(Float.self, forKey: key)
        case .stringAttributeType: value = try decode(String.self, forKey: key)
        case .booleanAttributeType: value = try decode(Bool.self, forKey: key)
        case .dateAttributeType: value = try decode(Date.self, forKey: key)
        case .binaryDataAttributeType: value = try decode(Data.self, forKey: key)
        case .UUIDAttributeType: value = try decode(UUID.self, forKey: key)
        case .URIAttributeType: value = try decode(URL.self, forKey: key)

        case .transformableAttributeType where attribute.valueTransformerName == nil || attribute.valueTransformerName == NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue:
            let anyNSCodable = try decode(AnyNSCodable.self, forKey: key)
            value = anyNSCodable?.value

        case .transformableAttributeType:
            guard let data = try decode(Data.self, forKey: key)
            else {
                value = nil
                break
            }

            guard
                let transformerName = attribute.valueTransformerName,
                let transformer = ValueTransformer(forName: NSValueTransformerName(transformerName))
            else { throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "The ValueTransformer for this value is invalid.") }

            value = transformer.reverseTransformedValue(data)

        case .undefinedAttributeType: fatalError("KeyedDecodingContainer.decodeManagedValue() does not yet support undefined attribute types.")
        case .objectIDAttributeType: fatalError("KeyedDecodingContainer.decodeManagedValue() does not yet support objectID attributes.")
        @unknown default: fatalError("KeyedDecodingContainer.decodeManagedValue() encountered unknown attribute type.")
        }

        return value
    }
}

extension KeyedEncodingContainer {
    mutating func encodeManagedValue(_ managedValue: Any?, forKey key: Key, entity: NSEntityDescription) throws {
        let context = EncodingError.Context(codingPath: codingPath + [key], debugDescription: "Managed object's property \(key.stringValue) could not be encoded.")

        guard let attribute = entity.attributesByName[key.stringValue]
        else {
            throw EncodingError.invalidValue(managedValue as Any, context)
        }

        if let value = managedValue {
            switch (attribute.attributeType, value) {
            case let (.integer16AttributeType, value as Int16): try encode(value, forKey: key)
            case let (.integer32AttributeType, value as Int32): try encode(value, forKey: key)
            case let (.integer64AttributeType, value as Int64): try encode(value, forKey: key)
            case let (.decimalAttributeType, value as Decimal): try encode(value, forKey: key)
            case let (.doubleAttributeType, value as Double): try encode(value, forKey: key)
            case let (.floatAttributeType, value as Float): try encode(value, forKey: key)
            case let (.stringAttributeType, value as String): try encode(value, forKey: key)
            case let (.booleanAttributeType, value as Bool): try encode(value, forKey: key)
            case let (.dateAttributeType, value as Date): try encode(value, forKey: key)
            case let (.binaryDataAttributeType, value as Data): try encode(value, forKey: key)
            case let (.UUIDAttributeType, value as UUID): try encode(value, forKey: key)
            case let (.URIAttributeType, value as URL): try encode(value, forKey: key)

            case let (.transformableAttributeType, value as NSCoding):
                let anyNSCodable = AnyNSCodable(value: value)
                try encode(anyNSCodable, forKey: key)

            case let (.transformableAttributeType, value):
                guard
                    let transformerName = attribute.valueTransformerName,
                    let transformer = ValueTransformer(forName: NSValueTransformerName(transformerName)),
                    let data = transformer.transformedValue(value) as? Data
                else { throw EncodingError.invalidValue(managedValue as Any, context) }

                try encode(data, forKey: key)

            case (.integer16AttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.integer32AttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.integer64AttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.decimalAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.doubleAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.floatAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.stringAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.booleanAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.dateAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.binaryDataAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.UUIDAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)
            case (.URIAttributeType, _): throw EncodingError.invalidValue(managedValue as Any, context)

            case (.undefinedAttributeType, _): fatalError("KeyedEncodingContainer.encodeManagedValue() does not yet support undefined attribute types.")
            case (.objectIDAttributeType, _): fatalError("KeyedEncodingContainer.encodeManagedValue() does not yet support objectID attributes.")
            @unknown default: fatalError("KeyedEncodingContainer.encodeManagedValue() encountered unknown attribute type.")
            }
        } else {
            try encodeNil(forKey: key)
        }
    }
}
