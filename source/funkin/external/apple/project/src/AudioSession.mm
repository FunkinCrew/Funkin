#import "AudioSession.hpp"

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>
#import <AVFAudio/AVFAudio.h>
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

void Apple_AudioSession_Initialize()
{
  #if TARGET_OS_IOS

  AVAudioSession *session = [AVAudioSession sharedInstance];

  NSError *error;

  [session setCategory:AVAudioSessionCategorySoloAmbient error:nil];
  [session setActive:YES error:nil];

  [[NSNotificationCenter defaultCenter] addObserverForName:@"UISceneWillEnterForegroundNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    NSError *resumeError = nil;
    [session setCategory:AVAudioSessionCategorySoloAmbient withOptions:0 error:nil];

    [session setActive:YES error:&resumeError];

    if (resumeError)
      NSLog(@"AudioSession resume error: %@", resumeError);
    else
      NSLog(@"AudioSession resumed and reactivated");
  }];
  [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:&error];

  if (@available(iOS 17.0, *))
  {
    [session setPrefersInterruptionOnRouteDisconnect:false error:nil];
  }

  if (@available(iOS 14.5, *))
  {
    [session setPrefersNoInterruptionsFromSystemAlerts:true error:nil];
  }

  if (error)
    NSLog(@"Unable to set category of audio session: %@", error);
  #endif
}

void Apple_AudioSession_SetActive(bool active)
{
  #if TARGET_OS_IOS
  AVAudioSession *session = [AVAudioSession sharedInstance];

  NSError *error;

  [session setActive:active error:&error];

  if (error)
    NSLog(@"Unable to set active of audio session: %@", error);
  #endif
}
