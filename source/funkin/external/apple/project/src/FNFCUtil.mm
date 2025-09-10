#import <Foundation/Foundation.h>

const char* copyFNFCIntoCache(const char *url)
{
  if (!url) return NULL;

  NSString *urlString = [NSString stringWithUTF8String:url];
  NSURL *fileURL = [NSURL URLWithString:urlString];

  if (!fileURL || ![fileURL isFileURL]) {
    return NULL;
  }

  NSString *sourcePath = [fileURL path];
  NSString *filename = [sourcePath lastPathComponent];

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cacheDir = [[paths firstObject] stringByAppendingPathComponent:@"fnfc"];

  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:cacheDir]) {
    [fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
  }

  NSString *destPath = [cacheDir stringByAppendingPathComponent:filename];

  NSError *error = nil;
  if ([fm fileExistsAtPath:destPath]) {
    [fm removeItemAtPath:destPath error:nil];
  }

  if (![fm copyItemAtPath:sourcePath toPath:destPath error:&error]) {
    return NULL;
  }

  return strdup([destPath UTF8String]);
}
