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
#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

#endif /* bridge_h */
