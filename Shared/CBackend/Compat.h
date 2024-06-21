//
//  Compat.h
//  PurePKG
//
//  Created by Lrdsnow on 6/16/24.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISheetPresentationControllerDetent (Private)
+ (UISheetPresentationControllerDetent *)_detentWithIdentifier:(NSString *)identifier constant:(CGFloat)constant;
@end

@interface CustomDetent : NSObject

+ (instancetype)customDetentWithConstant:(CGFloat)constant;

@end

NS_ASSUME_NONNULL_END
#endif
