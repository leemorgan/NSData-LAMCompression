//
//  NSData+LAMCompression.m
//  Compression
//
//  Created by Lee Morgan on 7/12/15.
//  Copyright © 2015 Lee Morgan. All rights reserved.
//

#import "NSData+LAMCompression.h"
#import <compression.h>

@interface NSData (LAMCompression_Private)

typedef NS_ENUM(NSUInteger, LAMCompressionOperation) {
	LAMCompressionEncode,
	LAMCompressionDecode,
};

@end


@implementation NSData (LAMCompression)

//--------------------
// Public methods
//--------------------

+ (NSData *)lam_dataWithContentsOfArchive:(NSString *)path {
	return [[NSData alloc] lam_initWithContentsOfArchive:path];
}

+ (NSData *)lam_dataWithContentsOfArchive:(NSString *)path usedCompression:(LAMCompression)compression {
	return [[NSData alloc] lam_initWithContentsOfArchive:path compression:compression];
}

- (NSData *)lam_initWithContentsOfArchive:(NSString *)path {
	
	NSData *compressedData = [NSData dataWithContentsOfFile:path];
	
	if (compressedData == nil) {
		return nil;
	}
	
	NSString *ext = [[path pathExtension] lowercaseString];
	
	LAMCompression compression;
	if ([ext isEqualToString:@"lz4"]) {
		compression = LAMCompressionLZ4;
	}
	else if ([ext isEqualToString:@"zlib"]) {
		compression = LAMCompressionZLIB;
	}
	else if ([ext isEqualToString:@"lzma"]) {
		compression = LAMCompressionLZMA;
	}
	else if ([ext isEqualToString:@"lzfse"]) {
		compression = LAMCompressionLZFSE;
	}
	else {
		return nil;
	}
	
	return [compressedData lam_uncompressedDataUsingCompression:compression];
}

- (NSData *)lam_initWithContentsOfArchive:(NSString *)path compression:(LAMCompression)compression {
	
	NSAssert(compression == LAMCompressionLZ4  ||
			 compression == LAMCompressionZLIB ||
			 compression == LAMCompressionLZMA ||
			 compression == LAMCompressionLZFSE, @"Invalid compression type specified");
	
	NSData *compressedData = [NSData dataWithContentsOfFile:path];
	
	if (compressedData == nil) {
		return nil;
	}
	
	return [compressedData lam_uncompressedDataUsingCompression:compression];
}

- (NSData *)lam_compressedDataUsingCompression:(LAMCompression)compression {
	return [self lam_dataUsingCompression:compression operation:LAMCompressionEncode];
}

- (NSData *)lam_uncompressedDataUsingCompression:(LAMCompression)compression {
	return [self lam_dataUsingCompression:compression operation:LAMCompressionDecode];
}


//--------------------
// Private methods
//--------------------

- (NSData *)lam_dataUsingCompression:(LAMCompression)compression operation:(NSUInteger)operation {
	
	NSAssert(compression == LAMCompressionLZ4  ||
			 compression == LAMCompressionZLIB ||
			 compression == LAMCompressionLZMA ||
			 compression == LAMCompressionLZFSE, @"Invalid compression type specified");
	
	NSAssert(operation == LAMCompressionEncode ||
			 operation == LAMCompressionDecode, @"Invalid operation specified");
	
	if (self.length == 0) {
		return nil;
	}
	
	compression_stream stream;
	compression_status status;
	compression_stream_operation op;
	compression_stream_flags flags;
	compression_algorithm algorithm;
	
	switch (compression) {
		case LAMCompressionLZ4:
			algorithm = COMPRESSION_LZ4;
			break;
		case LAMCompressionLZFSE:
			algorithm = COMPRESSION_LZFSE;
			break;
		case LAMCompressionLZMA:
			algorithm = COMPRESSION_LZMA;
			break;
		case LAMCompressionZLIB:
			algorithm = COMPRESSION_ZLIB;
			break;
		default:
			return nil;
			break;
	}
	
	switch (operation) {
		case LAMCompressionEncode:
			op = COMPRESSION_STREAM_ENCODE;
			flags = COMPRESSION_STREAM_FINALIZE;
			break;
		case LAMCompressionDecode:
			op = COMPRESSION_STREAM_DECODE;
			flags = 0;
			break;
		default:
			return nil;
			break;
	}
	
	status = compression_stream_init(&stream, op, algorithm);
	if (status == COMPRESSION_STATUS_ERROR) {
		// an error occurred
		return nil;
	}
	
	// setup the stream's source
	stream.src_ptr    = self.bytes;
	stream.src_size   = self.length;
	
	// setup the stream's output buffer
	// we use a temporary buffer to store data as it's compressed
	size_t dstBufferSize = 4096;
	uint8_t*dstBuffer    = malloc(dstBufferSize);
	stream.dst_ptr       = dstBuffer;
	stream.dst_size      = dstBufferSize;
	// and we store the output in a mutable data object
	NSMutableData *outputData = [NSMutableData new];
	
	do {
		status = compression_stream_process(&stream, flags);
		
		switch (status) {
			case COMPRESSION_STATUS_OK:
				// Going to call _process at least once more, so prepare for that
				if (stream.dst_size == 0) {
					// Output buffer full...
					
					// Write out to mutableData
					[outputData appendBytes:dstBuffer length:dstBufferSize];
					
					// Re-use dstBuffer
					stream.dst_ptr = dstBuffer;
					stream.dst_size = dstBufferSize;
				}
				break;
				
			case COMPRESSION_STATUS_END:
				// We are done, just write out the output buffer if there's anything in it
				if (stream.dst_ptr > dstBuffer) {
					[outputData appendBytes:dstBuffer length:stream.dst_ptr - dstBuffer];
				}
				break;
				
			case COMPRESSION_STATUS_ERROR:
				return nil;
				
			default:
				break;
		}
	} while (status == COMPRESSION_STATUS_OK);
	
	compression_stream_destroy(&stream);
	free(dstBuffer);
	
	return [outputData copy];
}

@end
