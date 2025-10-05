#include "FNFCUtil.hpp"
#import <Foundation/Foundation.h>

static FNFCCallback fnfcCallback = nullptr;

void copyFNFCIntoCache(const char *url, FNFCCallback callback)
{
  if (!fnfcCallback) {
	  fnfcCallback = callback;
  }

  if (!url) {
    if (fnfcCallback) {
		  dispatch_async(dispatch_get_main_queue(), ^{
		   fnfcCallback("FNFC_URL_NIL", "The URL passed to the conversion was null.");
		  });
	  }
    return;
  }

  NSString *urlString = [NSString stringWithUTF8String:url];
  NSURL *fileURL = [NSURL URLWithString:urlString];
  if (!fileURL || !fileURL.isFileURL) {
    fileURL = [NSURL fileURLWithPath:urlString];
  }

  if (!fileURL || !fileURL.isFileURL) {
    if (fnfcCallback) {
		  dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = [NSString stringWithFormat:@"The passed URL '%@' doesn't point at a FNFC file.", urlString];
		   fnfcCallback("FNFC_FILE_MISMATC", [msg UTF8String]);
		  });
	  }
    return;
  }

  BOOL accessed = [fileURL startAccessingSecurityScopedResource];
  if (!accessed) {
    if (fnfcCallback) {
		  dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = [NSString stringWithFormat:@"Failed to get access to URL '%@'.", urlString];
		   fnfcCallback("FNFC_FILE_ACCESS_ERR", [msg UTF8String]);
		  });
	  }
  }

  NSString *sourcePath = [fileURL path];
  NSString *filename = [sourcePath lastPathComponent];

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cacheDir = [[paths firstObject] stringByAppendingPathComponent:@"fnfc"];

  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *dirError = nil;
  if (![fm fileExistsAtPath:cacheDir]) {
    if(![fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&dirError]) {
      if (fnfcCallback) {
		    dispatch_async(dispatch_get_main_queue(), ^{
          NSString *msg = [NSString stringWithFormat:@"Failed to create directory %@: %@", cacheDir, dirError];
			    fnfcCallback("FNFC_DIR_CREATE_ERR", [msg UTF8String]);
		    });
	    }
    }
  }

  NSString *destPath = [cacheDir stringByAppendingPathComponent:filename];

  NSError *error = nil;
  if ([fm fileExistsAtPath:destPath]) {
    [fm removeItemAtPath:destPath error:nil];
  }

  if (![fm copyItemAtPath:sourcePath toPath:destPath error:&error]) {
    if (fnfcCallback) {
		  dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = [NSString stringWithFormat:@"Failed to copy FNFC from URL %@ to directory %@: %@", sourcePath, destPath, error];
		   fnfcCallback("FNFC_COPY_ERR", [msg UTF8String]);
		  });
	  }
    if (accessed) {
      [fileURL stopAccessingSecurityScopedResource];
    }
    return;
  }

  if (accessed) {
    [fileURL stopAccessingSecurityScopedResource];
  }

  if (fnfcCallback) {
    const char *val = strdup([destPath UTF8String]);
	  dispatch_async(dispatch_get_main_queue(), ^{
		fnfcCallback("FNFC_RESULTS", val);
      free((void *)val);
		});
	}
}
