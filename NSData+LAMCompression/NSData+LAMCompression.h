//
//  NSData+LAMCompression.h
//  Compression
//
//  Created by Lee Morgan on 7/12/15.
//  Copyright © 2015 Lee Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>


/** Available Compression Algorithms
 
 LAMCompressionLZ4
 
 LAMCompressionZLIB
 
 LAMCompressionLZMA
 
 LAMCompressionLZFSE
 */
typedef NS_ENUM(NSUInteger, LAMCompression) {
	
	/// Fast compression
	LAMCompressionLZ4,
	
	/// Balanced between speed and compression
	LAMCompressionZLIB,
	
	/// High Compression
	LAMCompressionLZMA,
	
	/// Apple-specific high performance compression. Faster and better compression than ZLIB, but slower than LZ4 and does not compress as well as LZMA.
	LAMCompressionLZFSE,
};


@interface NSData (LAMCompression)

/** Returns a NSData object created by compressing the receiver using the given compression algorithm.
 @return
 A NSData object created by compressing receiver using the given compression algorithm. If there is a compression error, returns nil.
 */
- (NSData *)lam_compressedDataUsingCompression:(LAMCompression)compression;


/** Returns a NSData object by uncompressing the receiver using the given compression algorithm.
 @return
 A NSData object by uncompressing the receiver using the given compression algorithm. If there is an uncompression error, returns nil.
 */
- (NSData *)lam_uncompressedDataUsingCompression:(LAMCompression)compression;

@end
