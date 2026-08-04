#include "URLSchemeExtern.hpp"
#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ApplicationServices/ApplicationServices.h>
#endif

static URLSchemeCallback urlSchemeCallback = nullptr;

static NSMutableArray<NSString *> *pendingURLs = nil;

#if TARGET_OS_OSX
@interface FunkinURLSchemeListener : NSObject
+ (instancetype)shared;
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;
@end

@implementation FunkinURLSchemeListener

+ (instancetype)shared
{
  static FunkinURLSchemeListener *instance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    instance = [[FunkinURLSchemeListener alloc] init];
  });

  return instance;
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
  NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

  if (url == nil)
  {
    return;
  }

  if (urlSchemeCallback != nullptr)
  {
    urlSchemeCallback([url UTF8String]);
    return;
  }

  if (pendingURLs == nil)
  {
    pendingURLs = [[NSMutableArray alloc] init];
  }

  [pendingURLs addObject:url];
}

@end

#endif

void Apple_URLScheme_InstallHandler()
{
#if TARGET_OS_OSX
  [[NSAppleEventManager sharedAppleEventManager] setEventHandler:[FunkinURLSchemeListener shared]
                                                     andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                                                   forEventClass:kInternetEventClass
                                                      andEventID:kAEGetURL];
#endif
}

bool Apple_URLScheme_Register(const char *scheme)
{
#if TARGET_OS_OSX
  if (scheme == NULL)
  {
    return false;
  }

  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

  if (bundleID == nil)
  {
    return false;
  }

  NSString *schemeString = [NSString stringWithUTF8String:scheme];

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  OSStatus status = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)schemeString, (__bridge CFStringRef)bundleID);
  #pragma clang diagnostic pop

  return status == noErr;
#else
  return false;
#endif
}

bool Apple_URLScheme_IsRegistered(const char *scheme)
{
#if TARGET_OS_OSX
  if (scheme == NULL)
  {
    return false;
  }

  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

  if (bundleID == nil)
  {
    return false;
  }

  NSString *schemeString = [NSString stringWithUTF8String:scheme];

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  CFStringRef handler = LSCopyDefaultHandlerForURLScheme((__bridge CFStringRef)schemeString);
  #pragma clang diagnostic pop

  if (handler == NULL)
  {
    return false;
  }

  bool matches = [bundleID caseInsensitiveCompare:(__bridge NSString *)handler] == NSOrderedSame;

  CFRelease(handler);

  return matches;
#else
  return false;
#endif
}

void Apple_URLScheme_SetCallback(URLSchemeCallback callback)
{
#if TARGET_OS_OSX
  // Install the URL scheme handler if it hasn't been installed yet
  Apple_URLScheme_InstallHandler();

  urlSchemeCallback = callback;

  if (callback == nullptr || pendingURLs == nil)
  {
    return;
  }

  NSArray<NSString *> *buffered = [pendingURLs copy];

  [pendingURLs removeAllObjects];

  for (NSString *url in buffered)
  {
    callback([url UTF8String]);
  }
#endif
}
