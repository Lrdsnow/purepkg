//
//  PaymentAPI_tvOS.h
//  PurePKG
//
//  Created by Lrdsnow on 6/15/24.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

@interface PaymentAPI_WebAuthenticationCoordinator_objc : NSObject

- (void)authWithURL:(NSURL *)url completion:(void (^)(NSURL * _Nullable authenticatedURL))completionHandler;

@property id webView;

@end

NS_ASSUME_NONNULL_END

#endif
