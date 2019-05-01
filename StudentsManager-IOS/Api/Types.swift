//
//  Types.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 30/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

// class representing data structure under sessions collection entity
final class Session
{
    static let active = String("active")
    static let host = String("host")
    static let createdBy = String("createdBy")
    static let name = String("name")
    static let room = String("room")
    static let startTime = String("startTime")
}

// class representing data structure under sessions collection entity
final class ApiUser
{
    static let displayName = String("displayName")
    static let email = String("email")
    static let phone = String("phone")
    static let selectedSession = String("selectedSession")
}

// class representing data structure under rooms collection entity
final class Room
{
    static let name = String("name")
}
