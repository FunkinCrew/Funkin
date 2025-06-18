package funkin.ui.options;

import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import funkin.util.MathUtil;

/**
 *  Extends the default flixel soundtray, but with some art
 *  and lil polish!
 *
 *  Gets added to the game in Main.hx, right after FlxGame is new'd
 *  since it's a Sprite rather than Flixel related object
 */
class FunkinSoundTray extends FlxSoundTray
{
  var graphicScale:Float = 0.30;
  var lerpYPos:Float = 0;
  var alphaTarget:Float = 0;

  var volumeMaxSound:String;

  public function new()
  {
    // calls super, then removes all children to add our own
    // graphics
    super();
    removeChildren();

    var bg:Bitmap = new Bitmap(Assets.getBitmapData(Paths.image("soundtray/volumebox")));
    bg.scaleX = graphicScale;
    bg.scaleY = graphicScale;
    bg.smoothing = true;
    addChild(bg);

    y = -height;
    visible = false;

    // makes an alpha'd version of all the bars (bar_10.png)
    var backingBar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.image("soundtray/bars_10")));
    backingBar.x = 9;
    backingBar.y = 5;
    backingBar.scaleX = graphicScale;
    backingBar.scaleY = graphicScale;
    backingBar.smoothing = true;
    addChild(backingBar);
    backingBar.alpha = 0.4;

    // clear the bars array entirely, it was initialized
    // in the super class
    _bars = [];

    // 1...11 due to how block named the assets,
    // we are trying to get assets bars_1-10
    for (i in 1...11)
    {
      var bar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.image("soundtray/bars_" + i)));
      bar.x = 9;
      bar.y = 5;
      bar.scaleX = graphicScale;
      bar.scaleY = graphicScale;
      bar.smoothing = true;
      addChild(bar);
      _bars.push(bar);
    }

    screenCenter();

    volumeUpSound = Paths.sound("soundtray/Volup");
    volumeDownSound = Paths.sound("soundtray/Voldown");
    volumeMaxSound = Paths.sound("soundtray/VolMAX");
  }

  override public function update(ms:Float):Void
  {
    y = MathUtil.smoothLerpPrecision(y, lerpYPos, ms / 1000, 0.768);
    alpha = MathUtil.smoothLerpPrecision(alpha, alphaTarget, ms / 1000, 0.307);

    // If it has volume, we want to auto-hide after 1 second (1000ms), we simply decrement a timer
    var hasVolume:Bool = (!FlxG.sound.muted && FlxG.sound.volume > 0);

    if (hasVolume)
    {
      // Animate sound tray thing
      if (_timer > 0)
      {
        _timer -= (ms / 1000);
      }
      else if (y >= -height)
      {
        lerpYPos = -height - 10;
        alphaTarget = 0;
      }

      if (y <= -height)
      {
        visible = false;
        active = false;
      }
    }
    else if (!visible) moveTrayMakeVisible();
  }

  /**
   * Makes the little volume tray slide out.
   * This is usually called by SoundFrontEnd, rather than being called by us explicitly
   * (Which is why it's internals have been separated out a bit, for easier internal calling)
   *
   * @param	up Whether the volume is increasing.
   */
  override public function show(up:Bool = false):Void
  {
    moveTrayMakeVisible(up);
    saveVolumePreferences();
  }

  function moveTrayMakeVisible(up:Bool = false):Void
  {
    _timer = 1;
    lerpYPos = 10;
    visible = true;
    active = true;
    alphaTarget = 1;

    for (i in 0..._bars.length)
      _bars[i].visible = i < getGlobalVolume(up);
  }

  /**
   * Calculates the volume with proper linear scaling, and returns it as an int.
   * @param up Whether the volume is increasing.
   * @return Int The volume as an int from 0 to 10.
   */
  function getGlobalVolume(up:Bool = false):Int
  {
    var globalVolume:Int = Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);

    if (FlxG.sound.muted || FlxG.sound.volume == 0) globalVolume = 0;

    if (!silent)
    {
      // This is a String currently, but there is or was a Flixel PR to change this to a FlxSound or a Sound bject
      var sound:String = up ? volumeUpSound : volumeDownSound;

      if (globalVolume == 10) sound = volumeMaxSound;
      if (sound != null) FlxG.sound.load(sound).play().volume = 0.3;
    }

    return globalVolume;
  }

  function saveVolumePreferences():Void
  {
    // Actually save when the volume is changed / modified
    #if FLX_SAVE
    // Save sound preferences
    if (FlxG.save.isBound)
    {
      FlxG.save.data.mute = FlxG.sound.muted;
      FlxG.save.data.volume = FlxG.sound.volume;
      FlxG.save.flush();
    }
    #end
  }
}
