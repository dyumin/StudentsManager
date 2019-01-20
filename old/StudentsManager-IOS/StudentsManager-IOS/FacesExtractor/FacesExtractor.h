//
//  FacesExtractor.h
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/09/2018.
//  Copyright © 2018 Bauman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FacesExtractor : NSObject

//@property UIImage* imageToSet;

+ (NSArray<UIImage *> *)getFaceImagesFromImageAtPath:(NSString*)imagePath;

@end

NS_ASSUME_NONNULL_END
