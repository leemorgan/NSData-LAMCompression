//
//  main.m
//  lamCompress
//
//  Created by Lee Morgan on 12/05/2018.
//  Copyright © 2018 Lee Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+LAMCompression.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool
    {
        if (argc != 4)
        {
            NSLog(@"usage: %s <-c=LZ4|ZLIB|LZMA|LZFSE> inputFile outputFile", argv[0]);
            return 1;
        }
        
        LAMCompression c = LAMCompressionZLIB;
        
        if ([@(argv[1]) isEqualToString:@"-c=LZ4"])
            c = LAMCompressionLZ4;
        else if ([@(argv[1]) isEqualToString:@"-c=ZLIB"])
            c = LAMCompressionZLIB;
        else if ([@(argv[1]) isEqualToString:@"-c=LZMA"])
            c = LAMCompressionLZMA;
        else if ([@(argv[1]) isEqualToString:@"-c=LZFSE"])
            c = LAMCompressionLZFSE;
        else
            NSLog(@"invalid compression method specified - defaulting to ZLIB");
        
        NSString *inputPath = @(argv[2]);
        NSData *inputData = [NSData dataWithContentsOfFile:inputPath];
        
        
        NSString *outputPath = @(argv[3]);
        NSData *outputData = [inputData lam_compressedDataUsingCompression:c];
        
        [outputData writeToFile:outputPath atomically:YES];
        
    }
    return 0;
}
