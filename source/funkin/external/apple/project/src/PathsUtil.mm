#import "PathsUtil.hpp"

#import <Foundation/Foundation.h>

const char *Apple_PathsUtil_GetCacheDirectory()
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

  NSString *cacheDirectory = [paths.firstObject stringByAppendingPathComponent:@"Caches"];

  return [cacheDirectory UTF8String];
}
