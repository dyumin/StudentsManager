//
//  String+UUUUUIKit.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 02/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation
import CommonCrypto

// https://stackoverflow.com/questions/25761344/how-to-hash-nsstring-with-sha1-in-swift
extension String
{
    func sha1() -> String
    {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes
        {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}
