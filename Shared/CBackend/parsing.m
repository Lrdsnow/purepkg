//
//  parsing.m
//  PurePKG
//
//  Created by Lrdsnow on 6/21/24.
//

#include <Foundation/Foundation.h>
#include "parsing.h"

NSMutableArray *genArrayOfDicts(NSString *content) {
    NSMutableArray *arrayOfDictionaries = [NSMutableArray array];
    NSArray *paragraphs = [content componentsSeparatedByString:@"\n\n"];
    
    for (NSString *paragraph in paragraphs) {
        NSMutableDictionary *dictionary = genDict(paragraph);
        
        if ([dictionary count] > 0) {
            [arrayOfDictionaries addObject:dictionary];
        }
    }
    
    return arrayOfDictionaries;
}

NSMutableDictionary *genDict(NSString *paragraph) {
    NSArray *lines = [paragraph componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    for (NSString *line in lines) {
        NSScanner *scanner = [NSScanner scannerWithString:line];
        NSString *key, *value;

        [scanner scanUpToString:@":" intoString:&key];
        [scanner scanString:@":" intoString:NULL];
        value = [line substringFromIndex:scanner.scanLocation];

        if (key && value) {
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            dictionary[key] = value;
        }
    }

    return dictionary;
}
