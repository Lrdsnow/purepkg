//
//  macOS.m
//  PurePKG
//
//  Created by Lrdsnow on 6/18/24.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_MAC
#import <Security/Authorization.h>

static void handleError(NSError *error, int *status, NSString **errorMessage) {
    if (error) {
        *status = (int)error.code;
        *errorMessage = error.localizedDescription;
    }
}

NS_ASSUME_NONNULL_BEGIN
extern void spawnRootHelper_macOS(NSArray<NSString *> *args, int *status, NSString **output, NSString **errorMessage) {
    AuthorizationItem authItem = { kAuthorizationRightExecute, 0, NULL, 0 };
    AuthorizationRights authRights = { 1, &authItem };
    AuthorizationFlags authFlags = kAuthorizationFlagDefaults;
    AuthorizationRef authRef = NULL;
    
    OSStatus statusCreate = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, authFlags, &authRef);
    if (statusCreate != errAuthorizationSuccess || !authRef) {
        *status = (int)statusCreate;
        *errorMessage = @"Authorization failed";
        return;
    }
    
    NSString *executablePath = [[NSBundle mainBundle] executablePath];
    if (!executablePath) {
        *status = 1;
        *errorMessage = @"Failed to get the executable path";
        return;
    }
    
    NSMutableArray<NSString *> *argsReal = [NSMutableArray arrayWithObject:executablePath];
    [argsReal addObjectsFromArray:args];
    
    int argc = (int)argsReal.count;
    const char **argv = (const char **)malloc(sizeof(char *) * argc);
    
    for (int i = 0; i < argc; i++) {
        argv[i] = [argsReal[i] UTF8String];
    }
    
    FILE *pipe = NULL;
    AuthorizationFlags executeFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize;
    
    OSStatus statusExecute = AuthorizationExecuteWithPrivileges(authRef, executablePath.UTF8String, executeFlags, (char *const * _Nonnull)argv, &pipe);
    free(argv);
    
    if (statusExecute != errAuthorizationSuccess) {
        *status = (int)statusExecute;
        *errorMessage = @"AuthorizationExecuteWithPrivileges failed";
        AuthorizationFree(authRef, kAuthorizationFlagDefaults);
        return;
    }
    
    NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileno(pipe) closeOnDealloc:YES];
    NSData *data = [fileHandle readDataToEndOfFile];
    [fileHandle closeFile];
    
    *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    AuthorizationFree(authRef, kAuthorizationFlagDefaults);
    *status = 0;
    *errorMessage = @"";
}
NS_ASSUME_NONNULL_END
#endif
