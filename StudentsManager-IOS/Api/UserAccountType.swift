//
//  UserAccountType.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/04/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

public struct UserAccountType: RawRepresentable {
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension UserAccountType
{
    static let new = UserAccountType(rawValue: "new")
    
    static let admin = UserAccountType(rawValue: "admin")
    static let tutor = UserAccountType(rawValue: "tutor")
    static let student = UserAccountType(rawValue: "student")
}

public extension UserAccountType
{
    static let AccountTypesWithEditingPermissions = [ admin.rawValue, tutor.rawValue ]
}
