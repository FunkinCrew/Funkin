package funkin.graphics.video;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
import hxvlc.util.TrackDescription;
import funkin.Preferences;

/**
 * Not to be confused with FlxVideo, this is a hxvlc based video class
 * We override it simply to correct/control our volume easier.
 */
@:nullSafety
class FunkinVideoSprite extends FlxVideoSprite
{
  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);

    if (bitmap != null)
    {
      bitmap.onOpening.add(function():Void {
        if (bitmap != null)
        {
          bitmap.spuDelay = Preferences.globalOffset * 1000;

          trace("Applied subtitle delay: " + bitmap.spuDelay + " microseconds");

          bitmap.audioDelay = Preferences.globalOffset * 1000;

          trace("Applied audio delay: " + bitmap.audioDelay + " microseconds");
        }
      });
      bitmap.onPlaying.add(function():Void {
        if (bitmap != null)
        {
          final spuTracks:Array<TrackDescription> = bitmap.getSpuDescription();

          trace("Subtitle tracks found: " + spuTracks.length);

          for (i in 0...spuTracks.length)
          {
            final name = spuTracks[i].psz_name;

            trace("Subtitle Track " + i + ": \"" + name + "\"");

            if (name.toLowerCase().contains("english"))
            {
              bitmap.spuTrack = spuTracks[i].i_id;

              trace("Selected subtitle track ID: " + bitmap.spuTrack);
            }
          }

          final audioTracks:Array<TrackDescription> = bitmap.getAudioDescription();

          trace("Audio tracks found: " + audioTracks.length);

          for (i in 0...audioTracks.length)
          {
            final name = audioTracks[i].psz_name;

            trace("Audio Track " + i + ": \"" + name + "\"");

            if (name.toLowerCase().contains("english"))
            {
              bitmap.audioTrack = audioTracks[i].i_id;

              trace("Selected audio track ID: " + bitmap.audioTrack);
            }
          }
        }
      });
    }
  }
}
#end
