//
//  HarmonyMetadataKey+Keys.swift
//  Harmony
//
//  Created by Riley Testut on 11/5/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import Foundation

public typealias HarmonyMetadataKey = String

extension HarmonyMetadataKey
{
    static let recordedObjectType = HarmonyMetadataKey("harmony_recordedObjectType")
    static let recordedObjectIdentifier = HarmonyMetadataKey("harmony_recordedObjectIdentifier")
    
    static let relationshipIdentifier = HarmonyMetadataKey("harmony_relationshipIdentifier")
    
    static let isLocked = HarmonyMetadataKey("harmony_locked")
    
    static let previousVersionIdentifier = HarmonyMetadataKey("harmony_previousVersionIdentifier")
    static let previousVersionDate = HarmonyMetadataKey("harmony_previousVersionDate")
    
    static let sha1Hash = HarmonyMetadataKey("harmony_sha1Hash")
    
    static let author = HarmonyMetadataKey("harmony_author")
    static let localizedName = HarmonyMetadataKey("harmony_localizedName")
    
    public static var allHarmonyKeys: Set<HarmonyMetadataKey> {
        return [.recordedObjectType, .recordedObjectIdentifier, .relationshipIdentifier,
                .isLocked, .previousVersionIdentifier, .previousVersionDate,
                .sha1Hash, .author, .localizedName]
    }
}
//
//@objc
//public enum HarmonyMetadataKey: Int, RawRepresentable, CaseIterable {
//    case recordedObjectType = "harmony_recordedObjectType"
//    case recordedObjectIdentifier = "harmony_recordedObjectIdentifier"
//
//    case relationshipIdentifier = "harmony_relationshipIdentifier"
//
//    case isLocked = "harmony_locked"
//
//    case previousVersionIdentifier = "harmony_previousVersionIdentifier"
//    case previousVersionDate = "harmony_previousVersionDate"
//
//    case sha1Hash = "harmony_sha1Hash"
//
//    case author = "harmony_author"
//    case localizedName = "harmony_localizedName"
//
//    public static var allHarmonyKeys: Set<HarmonyMetadataKey> {
//        return Set(HarmonyMetadataKey.allCases)
//    }
//}
