//
//  NSDate+LocalString.m
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 19/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

#import "NSDate+LocalString.h"

@implementation NSDate (LocalString)

// https://stackoverflow.com/questions/2615833/objective-c-setting-nsdate-to-current-utc
-(NSString *)toLocalDate
{
    // it can be static, i know
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    NSTimeZone* timeZone = [NSTimeZone localTimeZone];
    
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString* dateString = [dateFormatter stringFromDate:self];
   
    return dateString;
}

@end
