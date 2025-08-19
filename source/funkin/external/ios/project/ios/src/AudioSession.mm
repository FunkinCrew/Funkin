#import <Foundation/Foundation.h>
#import <AVFAudio/AVFAudio.h>

void initialize()
{
    AVAudioSession *session = [AVAudioSession sharedInstance];

    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback
                    mode:AVAudioSessionModeDefault
                 options:AVAudioSessionCategoryOptionAllowBluetoothA2DP|AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
                  error:&error];

    if (@available(iOS 17.0, *))
    {
        [session setPrefersInterruptionOnRouteDisconnect:false error:nil];
    }

    if (@available(iOS 14.5, *))
    {
        [session setPrefersNoInterruptionsFromSystemAlerts:true error:nil];
    }

    if (error)
    {
        NSLog(@"Unable to set category of audio session: %@", error);
    }
}

void setActive(bool active)
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;

    [session setActive:YES error:&error];

    if (error)
    {
        NSLog(@"Unable to set active of audio session: %@", error);
    }
}
