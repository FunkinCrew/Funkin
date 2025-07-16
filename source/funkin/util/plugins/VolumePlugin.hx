package funkin.util.plugins;

import flixel.FlxBasic;

/**
 * Handles volume control in a way that is compatible with alternate control schemes.
 */
@:nullSafety
class VolumePlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize()
  {
    FlxG.plugins.addPlugin(new VolumePlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    var isHaxeUIFocused:Bool = haxe.ui.focus.FocusManager.instance?.focus != null;

    if (!isHaxeUIFocused)
    {
      // Rebindable volume keys.
      if (PlayerSettings.player1.controls.VOLUME_MUTE) FlxG.sound.toggleMuted();
      else if (PlayerSettings.player1.controls.VOLUME_UP) FlxG.sound.changeVolume(0.1);
      else if (PlayerSettings.player1.controls.VOLUME_DOWN) FlxG.sound.changeVolume(-0.1);
    }
  }

  override public function destroy():Void
  {
    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    super.destroy();
  }
}
