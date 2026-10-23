package funkin.external.apple;

#if ((ios || macos) && cpp)
/**
 * A utility class to manage the audio session on apple devices.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('AudioSession.hpp')
@:unreflective
extern class AudioSession
{
  /**
   * Initializes the audio session for playback.
   *
   * This function configures the shared AVAudioSession instance with the following settings:
   * - For iOS 17.0 and above, disables interruption on route disconnect.
   * - For iOS 14.5 and above, prefers no interruptions from system alerts.
   */
  @:native('Apple_AudioSession_Initialize')
  static function initialize():Void;
}
#end
