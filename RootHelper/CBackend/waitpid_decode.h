//
//  waitpid_decode.h
//  PurePKG
//
//  Created by Lrdsnow on 1/15/24.
//

#ifndef waitpid_decode_h
#define waitpid_decode_h

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/wait.h>

char* waitpid_decode(int status);
#endif /* waitpid_decode_h */

