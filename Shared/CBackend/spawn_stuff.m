//
//  spawn_stuff.m
//  PurePKG
//
//  Created by Lrdsnow on 3/27/24.
//

#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import "spawn_stuff.h"
#import "bridge.h"

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr) {
    NSMutableArray* argsM = args.mutableCopy ?: [NSMutableArray new];
    [argsM insertObject:path atIndex:0];
    
    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;

    posix_spawnattr_t attr;
    custom_posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    int32_t pipestatusfd[2] = {0, 0};
    int32_t pipestdout[2] = {0, 0};
    int32_t pipestderr[2] = {0, 0};
    int32_t pipesileo[2] = {0, 0};
    
    int bufsiz = BUFSIZ;
    
    pipe(pipestdout);
    pipe(pipestderr);
    pipe(pipestatusfd);
    pipe(pipesileo);
    
    char *sileoFDStr = getenv("SILEO_FD");
    int sileoFD = sileoFDStr ? atoi(sileoFDStr) : 0;
    
    char *env[] = {
        "SILEO=6 1",
        "CYDIA=6 1",
        "PATH='/usr/bin:/usr/local/bin:/bin:/usr/sbin:/var/jb/usr/bin:/var/jb/usr/local/bin:/var/jb/bin:/var/jb/usr/sbin:/opt/procursus/sbin:/opt/procursus/usr/bin:/opt/procursus/usr/local/bin:/opt/procursus/bin:/opt/procursus/usr/sbin:/opt/procursus/sbin'",
        NULL
    };
    
    posix_spawn_file_actions_t fileActions;
    custom_posix_spawn_file_actions_init(&fileActions);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[0]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[0]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestatusfd[0]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipesileo[0]);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipestdout[1], STDOUT_FILENO);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipestderr[1], STDERR_FILENO);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipestatusfd[1], 5);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipesileo[1], sileoFD);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[1]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[1]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestatusfd[1]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipesileo[1]);
    
    pid_t task_pid;
    int status = -200;
    int spawnError = custom_posix_spawn(&task_pid, [path UTF8String], &fileActions, &attr, (char* const*)argsC, env);
    custom_posix_spawnattr_destroy(&attr);
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);
    
    if(spawnError != 0)
    {
        NSLog(@"posix_spawn error %d\n", spawnError);
        return spawnError;
    }
    
    return 0;
}
