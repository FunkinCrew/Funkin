#include "FNFCExtern.hpp"
#import <Foundation/Foundation.h>

static FNFCCallback fnfcCallback = nullptr;
static FNFCCallback modArchiveCallback = nullptr;

void Apple_FNFCExtern_CopyFNFCIntoCache(const char *url, FNFCCallback callback)
{
  #if TARGET_OS_IOS
  if (!fnfcCallback)
  {
    fnfcCallback = callback;
  }

  if (!url)
  {
    if (fnfcCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        fnfcCallback("FNFC_URL_NIL", "The URL passed to the conversion was null.");
      });
    }

    return;
  }

  NSString *urlString = [NSString stringWithUTF8String:url];

  NSURL *fileURL = [NSURL URLWithString:urlString];

  if (!fileURL || !fileURL.isFileURL)
  {
    fileURL = [NSURL fileURLWithPath:urlString];
  }

  if (!fileURL || !fileURL.isFileURL)
  {
    if (fnfcCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        char *msg = strdup([[NSString stringWithFormat:@"The passed URL '%@' doesn't point at a FNFC file.", urlString] UTF8String]);
        fnfcCallback("FNFC_FILE_MISMATC", msg);
        free(msg);
      });
    }

    return;
  }

  BOOL accessed = [fileURL startAccessingSecurityScopedResource];

  if (!accessed)
  {
    if (fnfcCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        char *msg = strdup([[NSString stringWithFormat:@"Failed to get access to URL '%@'.", urlString] UTF8String]);
        fnfcCallback("FNFC_FILE_ACCESS_ERR", msg);
        free(msg);
      });
    }
  }

  NSString *sourcePath = [fileURL path];

  NSString *filename = [sourcePath lastPathComponent];

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

  NSString *cacheDir = [[paths firstObject] stringByAppendingPathComponent:@"fnfc"];

  NSFileManager *fm = [NSFileManager defaultManager];

  NSError *dirError = nil;

  if (![fm fileExistsAtPath:cacheDir])
  {
    if (![fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&dirError])
    {
      if (fnfcCallback)
      {
        dispatch_async(dispatch_get_main_queue(), ^{
          char *msg = strdup([[NSString stringWithFormat:@"Failed to create directory %@: %@", cacheDir, dirError] UTF8String]);
          fnfcCallback("FNFC_DIR_CREATE_ERR", msg);
          free(msg);
        });
      }
    }
  }

  NSString *destPath = [cacheDir stringByAppendingPathComponent:filename];

  NSError *error = nil;

  if ([fm fileExistsAtPath:destPath])
  {
    [fm removeItemAtPath:destPath error:nil];
  }

  if (![fm copyItemAtPath:sourcePath toPath:destPath error:&error])
  {
    if (fnfcCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        char *msg = strdup([[NSString stringWithFormat:@"Failed to copy FNFC from URL %@ to directory %@: %@", sourcePath, destPath, error] UTF8String]);
        fnfcCallback("FNFC_COPY_ERR", msg);
        free(msg);
      });
    }

    if (accessed)
    {
      [fileURL stopAccessingSecurityScopedResource];
    }

    return;
  }

  if (accessed)
  {
    [fileURL stopAccessingSecurityScopedResource];
  }

  if (fnfcCallback)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      char *val = strdup([destPath UTF8String]);
      fnfcCallback("FNFC_RESULTS", val);
      free(val);
    });
  }
  #endif
}

void Apple_ModArchiveExtern_CopyModArchiveIntoCache(const char *url, FNFCCallback callback)
{
  #if TARGET_OS_IOS
  if (!modArchiveCallback)
  {
    modArchiveCallback = callback;
  }

  if (!url)
  {
    if (modArchiveCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        modArchiveCallback("MOD_ARCHIVE_ERROR", "The URL passed to the conversion was null");
      });
    }

    return;
  }

  NSString *urlString = [NSString stringWithUTF8String:url];
  NSURL *fileURL = [NSURL URLWithString:urlString];

  if (!fileURL || !fileURL.isFileURL)
  {
    fileURL = [NSURL fileURLWithPath:urlString];
  }

  if (!fileURL || !fileURL.isFileURL)
  {
    if (modArchiveCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        char *message = strdup([[NSString stringWithFormat:@"The URL '%@' does not point to a local mod archive", urlString] UTF8String]);
        modArchiveCallback("MOD_ARCHIVE_ERROR", message);
        free(message);
      });
    }

    return;
  }

  BOOL accessed = [fileURL startAccessingSecurityScopedResource];

  NSString *sourcePath = [fileURL path];
  NSString *filename = [sourcePath lastPathComponent];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cacheDir = [[paths firstObject] stringByAppendingPathComponent:@"mod-archives"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *directoryError = nil;

  if (![fileManager fileExistsAtPath:cacheDir]
      && ![fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&directoryError])
  {
    if (modArchiveCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        char *message = strdup([[NSString stringWithFormat:@"Failed to create directory %@: %@", cacheDir, directoryError] UTF8String]);
        modArchiveCallback("MOD_ARCHIVE_ERROR", message);
        free(message);
      });
    }

    if (accessed) [fileURL stopAccessingSecurityScopedResource];
    return;
  }

  NSString *uniqueFilename = [NSString stringWithFormat:@"%@-%@", [[NSUUID UUID] UUIDString], filename];
  NSString *destinationPath = [cacheDir stringByAppendingPathComponent:uniqueFilename];
  NSError *copyError = nil;

  if (![fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&copyError])
  {
    if (modArchiveCallback)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        char *message = strdup([[NSString stringWithFormat:@"Failed to copy mod archive from URL %@ to directory %@: %@", sourcePath, destinationPath, copyError] UTF8String]);
        modArchiveCallback("MOD_ARCHIVE_ERROR", message);
        free(message);
      });
    }

    if (accessed) [fileURL stopAccessingSecurityScopedResource];
    return;
  }

  if (accessed) [fileURL stopAccessingSecurityScopedResource];

  if (modArchiveCallback)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      char *value = strdup([destinationPath UTF8String]);
      modArchiveCallback("MOD_ARCHIVE_RESULTS", value);
      free(value);
    });
  }
  #endif
}
