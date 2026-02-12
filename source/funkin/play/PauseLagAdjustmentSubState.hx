package funkin.play;

import flixel.sound.FlxSound;
import funkin.audio.FunkinSound;
import funkin.ui.MusicBeatSubState;
import funkin.ui.options.OffsetMenu;

class PauseLagAdjustmentSubState extends MusicBeatSubState
{
  var calibrationMusic:Null<FunkinSound>;
  var drumsMusic:Null<FunkinSound>;
  var offsetMenu:OffsetMenu;

  public function new()
  {
    super();
  }

  public override function create():Void
  {
    super.create();

    calibrationMusic = FunkinSound.load(Paths.music('offsetsLoop/offsetsLoop'), 0, true, false, false, false);
    drumsMusic = FunkinSound.load(Paths.music('offsetsLoop/drumsLoop'), 0, true, false, false, false);

    if (calibrationMusic != null)
    {
      calibrationMusic.play(true);
      calibrationMusic.fadeIn(0.35, 0, 1);
    }

    if (drumsMusic != null)
    {
      if (calibrationMusic != null) drumsMusic.time = calibrationMusic.time;
      drumsMusic.play(true);
      drumsMusic.fadeIn(0.35, 0, 1);
    }

    var timingTrack:Null<FlxSound> = calibrationMusic != null ? calibrationMusic : drumsMusic;

    offsetMenu = new OffsetMenu(false, false);
    offsetMenu.timingTrack = timingTrack;
    offsetMenu.drumsTrack = drumsMusic;
    offsetMenu.onExit.add(close);
    add(offsetMenu);
  }

  public override function destroy():Void
  {
    if (offsetMenu != null)
    {
      offsetMenu.onExit.remove(close);
    }

    super.destroy();

    if (drumsMusic != null)
    {
      drumsMusic.stop();
      drumsMusic.destroy();
      drumsMusic = null;
    }

    if (calibrationMusic != null)
    {
      calibrationMusic.stop();
      calibrationMusic.destroy();
      calibrationMusic = null;
    }
  }
}
