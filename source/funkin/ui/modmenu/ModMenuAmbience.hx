package funkin.ui.modmenu;

import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.audio.FunkinSoundscape;

/**
 * Handles the mod menu ambience that plays, along with various sound effects that play at random.
 */
@:nullSafety
class ModMenuAmbience extends FunkinSoundscape
{
  /**
   * The amount of time in seconds before the PhantomArcade easter egg plays.
   */
  public static final EASTER_EGG_TIMER:Float = 180.0;

  /**
   * The path to the PhantomArcade easter egg sound.
   */
  public static final EASTER_EGG_PATH:String = Paths.sound('ui/mods/sounds/phantomarcade-trapped');

  var _easterEgg:Null<FunkinSound> = null;

  public function new(params:FunkinSoundscapeSettings)
  {
    super(params);
  }

  override function playRandomSound():Void
  {
    super.playRandomSound();

    if (_currentSFX != null)
    {
      @:privateAccess
      var index:Int = Std.int(soundList.indexOf(_currentSFX._label));
      var usedWeight:Float = weights[index];

      if (usedWeight <= 1)
      {
        soundList.splice(index, 1);
        weights.splice(index, 1);
      }
    }
  }

  override function onSoundFadeIn(tween:FlxTween):Void
  {
    FlxTimer.wait(EASTER_EGG_TIMER, () ->
    {
      _easterEgg = FunkinSound.playOnce(EASTER_EGG_PATH);
    });

    super.onSoundFadeIn(tween);
  }

  override public function destroy():Void
  {
    super.destroy();

    if (_easterEgg != null) _easterEgg.destroy();
  }
}

