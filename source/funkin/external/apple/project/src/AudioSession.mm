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

  if (@available(iOS 17.0, *))
  {
    [session setPrefersInterruptionOnRouteDisconnect:false error:nil];
  }

  if (@available(iOS 14.5, *))
  {
    [session setPrefersNoInterruptionsFromSystemAlerts:true error:nil];
  }
  #endif
}
