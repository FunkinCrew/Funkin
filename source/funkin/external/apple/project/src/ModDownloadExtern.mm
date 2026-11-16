#include "ModDownloadExtern.hpp"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#include <cstdio>
#include <mutex>
#include <string>

#if __has_feature(objc_arc)
#define FUNKIN_RELEASE(x) (void)(x)
#else
#define FUNKIN_RELEASE(x) [x release]
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static std::mutex stateMutex;
static int state = APPLE_MOD_DOWNLOAD_IDLE;
static long long bytesLoaded = 0;
static long long bytesTotal = 0;
static std::string errorMessage;
static std::string digestHex;

// Bumped on every start and cancel, so callbacks from an abandoned download don't overwrite the state of a new one.
static unsigned int generation = 0;

static NSURLSession *activeSession = nil;

@interface FunkinModDownloadDelegate : NSObject <NSURLSessionDataDelegate>
{
  @public
  unsigned int generation;
  FILE *file;
  std::string destPath;
  CC_MD5_CTX md5;
  NSArray<NSString *> *allowedDomains;
}
@end

@implementation FunkinModDownloadDelegate

- (void)dealloc
{
  if (file != NULL) fclose(file);

  FUNKIN_RELEASE(allowedDomains);

#if !__has_feature(objc_arc)
  [super dealloc];
#endif
}

// Returns YES if the URL is HTTPS and the host is in the allowed list.
- (BOOL)isAllowed:(NSURL *)url
{
  if (url == nil || url.host == nil) return NO;
  if ([url.scheme caseInsensitiveCompare:@"https"] != NSOrderedSame) return NO;

  NSString *host = url.host.lowercaseString;

  for (NSString *domain in allowedDomains)
  {
    if ([host isEqualToString:domain] || [host hasSuffix:[@"." stringByAppendingString:domain]]) return YES;
  }

  return NO;
}

// Sets the error message if the download is still running and the generation matches.
- (void)failLocked:(NSString *)reason
{
  if (generation != ::generation || state != APPLE_MOD_DOWNLOAD_RUNNING || !errorMessage.empty()) return;

  errorMessage = reason.UTF8String ?: "The download failed.";
}

- (void)URLSession:(NSURLSession *)session
                          task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                    newRequest:(NSURLRequest *)request
             completionHandler:(void (^)(NSURLRequest *))completionHandler
{
  if ([self isAllowed:request.URL])
  {
    completionHandler(request);
    return;
  }

  {
    std::lock_guard<std::mutex> lock(stateMutex);
    [self failLocked:@"That download redirected somewhere we don't trust."];
  }

  completionHandler(nil);
  [task cancel];
}

- (void)URLSession:(NSURLSession *)session
              dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
  NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;

  std::lock_guard<std::mutex> lock(stateMutex);

  if (generation != ::generation)
  {
    completionHandler(NSURLSessionResponseCancel);
    return;
  }

  if (status < 200 || status >= 300)
  {
    [self failLocked:[NSString stringWithFormat:@"GameBanana refused the download (HTTP %ld).", (long)status]];
    completionHandler(NSURLSessionResponseCancel);
    return;
  }

  file = fopen(destPath.c_str(), "wb");

  if (file == NULL)
  {
    [self failLocked:@"Could not write the download to the mods folder."];
    completionHandler(NSURLSessionResponseCancel);
    return;
  }

  CC_MD5_Init(&md5);

  bytesLoaded = 0;
  if (response.expectedContentLength > 0) bytesTotal = response.expectedContentLength;

  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
  std::lock_guard<std::mutex> lock(stateMutex);

  if (generation != ::generation || file == NULL || !errorMessage.empty()) return;

  __block bool failed = false;

  [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange range, BOOL *stop) {
    if (fwrite(bytes, 1, range.length, file) != range.length)
    {
      failed = true;
      *stop = YES;
      return;
    }

    CC_MD5_Update(&md5, bytes, (CC_LONG)range.length);
    bytesLoaded += range.length;
  }];

  if (failed)
  {
    [self failLocked:@"Could not write the download to the mods folder, the device may be out of space."];
    [dataTask cancel];
  }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  bool closeFailed = false;

  if (file != NULL)
  {
    closeFailed = fclose(file) != 0;
    file = NULL;
  }

  NSURLSession *finished = nil;

  {
    std::lock_guard<std::mutex> lock(stateMutex);

    if (session == activeSession)
    {
      finished = activeSession;
      activeSession = nil;
    }

    if (generation == ::generation && state == APPLE_MOD_DOWNLOAD_RUNNING)
    {
      if (errorMessage.empty() && error != nil) [self failLocked:[@"The download failed. " stringByAppendingString:error.localizedDescription]];
      if (errorMessage.empty() && closeFailed) [self failLocked:@"Could not finish writing the download, the device may be out of space."];
      if (errorMessage.empty() && bytesLoaded == 0) [self failLocked:@"The download came back empty."];

      if (errorMessage.empty())
      {
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &md5);

        char hex[CC_MD5_DIGEST_LENGTH * 2 + 1];
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) snprintf(hex + i * 2, 3, "%02x", digest[i]);

        digestHex = hex;
        state = APPLE_MOD_DOWNLOAD_FINISHED;
      }
      else
      {
        state = APPLE_MOD_DOWNLOAD_FAILED;
      }
    }
  }

  // The session holds on to its delegate until it's invalidated.
  [session finishTasksAndInvalidate];

  FUNKIN_RELEASE(finished);
}

@end

bool Apple_ModDownload_Start(const char *url, const char *destPath, const char *userAgent, const char *allowedDomains, double timeout)
{
  if (url == NULL || destPath == NULL) return false;

  @autoreleasepool
  {
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
    if (requestURL == nil) return false;

    FunkinModDownloadDelegate *delegate = [[FunkinModDownloadDelegate alloc] init];
    delegate->file = NULL;
    delegate->destPath = destPath;

    NSString *domains = allowedDomains == NULL ? @"" : [NSString stringWithUTF8String:allowedDomains];
    NSMutableArray<NSString *> *domainList = [NSMutableArray array];

    for (NSString *domain in [domains componentsSeparatedByString:@","])
    {
      NSString *trimmed = [domain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].lowercaseString;
      if (trimmed.length > 0) [domainList addObject:trimmed];
    }

    delegate->allowedDomains = [domainList copy];

    if (![delegate isAllowed:requestURL])
    {
      FUNKIN_RELEASE(delegate);
      return false;
    }

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = timeout;
    if (userAgent != NULL) config.HTTPAdditionalHeaders = @{@"User-Agent" : [NSString stringWithUTF8String:userAgent]};

    // One at a time, so the callbacks never run alongside each other.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:delegate delegateQueue:queue];
#if !__has_feature(objc_arc)
    [session retain];
#endif

    FUNKIN_RELEASE(queue);

    NSURLSession *previous = nil;

    {
      std::lock_guard<std::mutex> lock(stateMutex);

      if (state == APPLE_MOD_DOWNLOAD_RUNNING)
      {
        previous = session;
        session = nil;
      }
      else
      {
        generation++;
        delegate->generation = generation;

        state = APPLE_MOD_DOWNLOAD_RUNNING;
        bytesLoaded = 0;
        bytesTotal = 0;
        errorMessage.clear();
        digestHex.clear();

        previous = activeSession;
        activeSession = session;
      }
    }

    FUNKIN_RELEASE(delegate);

    if (previous != nil)
    {
      [previous invalidateAndCancel];
      FUNKIN_RELEASE(previous);
    }

    if (session == nil) return false;

    [[session dataTaskWithURL:requestURL] resume];
  }

  return true;
}

void Apple_ModDownload_Cancel()
{
  NSURLSession *session = nil;

  {
    std::lock_guard<std::mutex> lock(stateMutex);

    generation++;
    state = APPLE_MOD_DOWNLOAD_IDLE;
    bytesLoaded = 0;
    bytesTotal = 0;
    errorMessage.clear();
    digestHex.clear();

    session = activeSession;
    activeSession = nil;
  }

  if (session != nil)
  {
    [session invalidateAndCancel];
    FUNKIN_RELEASE(session);
  }
}

int Apple_ModDownload_GetState()
{
  std::lock_guard<std::mutex> lock(stateMutex);
  return state;
}

double Apple_ModDownload_GetBytesLoaded()
{
  std::lock_guard<std::mutex> lock(stateMutex);
  return (double)bytesLoaded;
}

double Apple_ModDownload_GetBytesTotal()
{
  std::lock_guard<std::mutex> lock(stateMutex);
  return (double)bytesTotal;
}

const char *Apple_ModDownload_GetError()
{
  // Only written while the download is running.
  std::lock_guard<std::mutex> lock(stateMutex);
  return errorMessage.c_str();
}

const char *Apple_ModDownload_GetDigest()
{
  std::lock_guard<std::mutex> lock(stateMutex);
  return digestHex.c_str();
}

#pragma clang diagnostic pop
