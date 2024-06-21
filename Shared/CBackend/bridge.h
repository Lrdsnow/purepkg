//
//  bridge.h
//  PurePKG
//
//  Created by Lrdsnow on 1/15/24.
//

#ifndef bridge_h
#define bridge_h

#include "waitpid_decode.h"
#include <spawn.h>
#include "Compat.h"

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

int custom_posix_spawn(pid_t * __restrict, const char * __restrict,
    const posix_spawn_file_actions_t *,
    const posix_spawnattr_t * __restrict,
    char *const __argv[__restrict],
    char *const __envp[__restrict]) asm("_posix_spawn");

int custom_posix_spawnp(pid_t * __restrict, const char * __restrict,
    const posix_spawn_file_actions_t *,
    const posix_spawnattr_t * __restrict,
    char *const __argv[__restrict],
    char *const __envp[__restrict]) asm("_posix_spawnp");

int custom_posix_spawn_file_actions_addclose(posix_spawn_file_actions_t *, int) asm("_posix_spawn_file_actions_addclose");
int custom_posix_spawn_file_actions_adddup2(posix_spawn_file_actions_t *, int, int) asm("_posix_spawn_file_actions_adddup2");
int custom_posix_spawn_file_actions_addopen(posix_spawn_file_actions_t * __restrict, int, const char * __restrict, int, mode_t) asm("_posix_spawn_file_actions_addopen");
int custom_posix_spawn_file_actions_destroy(posix_spawn_file_actions_t *) asm("_posix_spawn_file_actions_destroy");
int custom_posix_spawn_file_actions_init(posix_spawn_file_actions_t *) asm("_posix_spawn_file_actions_init");
int custom_posix_spawnattr_destroy(posix_spawnattr_t *) asm("_posix_spawnattr_destroy");
int custom_posix_spawnattr_getsigdefault(const posix_spawnattr_t * __restrict, sigset_t * __restrict) asm("_posix_spawnattr_getsigdefault");
int custom_posix_spawnattr_getflags(const posix_spawnattr_t * __restrict, short * __restrict) asm("_posix_spawnattr_getflags");
int custom_posix_spawnattr_getpgroup(const posix_spawnattr_t * __restrict, pid_t * __restrict) asm("_posix_spawnattr_getpgroup");
int custom_posix_spawnattr_getsigmask(const posix_spawnattr_t * __restrict, sigset_t * __restrict) asm("_posix_spawnattr_getsigmask");
int custom_posix_spawnattr_init(posix_spawnattr_t *) asm("_posix_spawnattr_init");
int custom_posix_spawnattr_setsigdefault(posix_spawnattr_t * __restrict, const sigset_t * __restrict) asm("_posix_spawnattr_setsigdefault");
int custom_posix_spawnattr_setflags(posix_spawnattr_t *, short) asm("_posix_spawnattr_setflags");
int custom_posix_spawnattr_setpgroup(posix_spawnattr_t *, pid_t) asm("_posix_spawnattr_setpgroup");
int custom_posix_spawnattr_setsigmask(posix_spawnattr_t * __restrict, const sigset_t * __restrict) asm("_posix_spawnattr_setsigmask");

#endif /* bridge_h */
