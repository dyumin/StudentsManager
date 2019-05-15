//
//  Types.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 30/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

// TODO: share with server sources
// class representing data structure under sessions collection entity
final class Session
{
    static let active = "active"
    static let host = "host"
    static let createdBy = "createdBy"
    static let name = "name"
    static let room = "room"
    static let startTime = "startTime"
    static let participants = "attendees"
    
    // Collection
    static let resources = "resources"
}

// class representing data structure under users collection entity
final class ApiUser
{
    static let displayName = "displayName"
    static let email = "email"
    static let phone = "phone"
    static let selectedSession = "selectedSession"
}

// class representing data structure under rooms collection entity
final class Room
{
    static let name = "name"
}

// TODO: share with server sources
// class representing data structure under Session/resources collection entity
final class ResourceRecord
{
    static let imagePath = "imagePath" // String
    static let processed = "processed" // Bool
}

// TODO: share with server sources
// class representing data structure under processingQueue collection entity
final class ProcessingQueue
{
    static let imagePath = "imagePath" // String
    static let session = "session" // DocumentReference
    static let imageMeta = "imageMeta" // DocumentReference
    
    static let active = "active" // Bool
    static let lastUpdateTime = "lastUpdateTime" // Timestamp
}
