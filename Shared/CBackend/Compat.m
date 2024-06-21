//
//  Compat.m
//  PurePKG
//
//  Created by Lrdsnow on 6/17/24.
//

#import "Compat.h"

#if TARGET_OS_IOS || TARGET_OS_TV
@implementation CustomDetent

+ (instancetype)customDetentWithConstant:(CGFloat)constant {
    UISheetPresentationControllerDetent *detent = [UISheetPresentationControllerDetent _detentWithIdentifier:@"custom_detent" constant:constant];
    return detent;
}

@end
#endif
