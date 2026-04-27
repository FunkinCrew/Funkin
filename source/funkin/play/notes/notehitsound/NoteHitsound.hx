package funkin.play.notes.notehitsound;

import funkin.audio.FunkinSound;

/**
 * Handles playback of note hitsounds, routing to the correct audio asset
 * based on the user's selected `NoteHitsoundType`.
 */
class NoteHitsound extends FunkinSound
{
  /**
   * The base asset path for all hitsound files.
   */
  static final HITSOUND_PATH:String = 'gameplay/hitsounds/';

  /**
   * Play a hitsound of the given type at the given volume.
   *
   * @param type The hitsound type to play.
   * @param volume `Preferences.hitsoundVolume` from 0.0 to 1.0.
   * @return The playing `FunkinSound`, or `null`.
   */
  public static function playType(type:NoteHitsoundType = NoteHitsoundType.Default, volume:Float = 1.0):Null<FunkinSound>
  {
    if (type == NoteHitsoundType.None || volume <= 0.0) return null;

    var path:Null<String> = getAssetPath(type);
    if (path == null) return null;

    var sound:Null<FunkinSound> = FunkinSound.playOnce(Paths.sound(path), volume);
    if (sound != null) sound.volume = volume;
    return sound;
  }

  /**
   * Resolve the asset path for a given `NoteHitsoundType`.
   *
   * @param type The hitsound type to play.
   * @return The asset path string, or `null` if not found.
   */
  public static function getAssetPath(type:NoteHitsoundType):Null<String>
  {
    return switch (type)
    {
      case NoteHitsoundType.Default: return HITSOUND_PATH + 'hitsound_DEFAULT';
      case NoteHitsoundType.PingPong: return HITSOUND_PATH + 'hitsound_PINGPONG';
      case NoteHitsoundType.None: return null;
      default: return null;
    }
  }
}

/**
 * The different types of note hitsounds available.
 * Note: Any new hitsound types must be added here, and in `NoteHitsound.getAssetPath()`.
 */
abstract NoteHitsoundType(String) from String to String
{
  /**
   * The note hitsound option is fully disabled.
   */
  public static inline var None:NoteHitsoundType = "None";

  /**
   * The default note hitsound.
   * Can be heard when using the chart editor.
   */
  public static inline var Default:NoteHitsoundType = "Default";

  /**
   * Custom ping pong note hitsound.
   */
  public static inline var PingPong:NoteHitsoundType = "Ping Pong";
}
