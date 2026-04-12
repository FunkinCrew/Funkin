package funkin.ui.options;

import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import funkin.util.MathUtil;
//
// ~PATHS~
//
import funkin.assets.Assets as Assets;
import funkin.assets.ValidatedPaths as Paths;

/**
 *  Extends the default flixel soundtray, but with some art
 *  and lil polish!
 *
 *  Gets added to the game in Main.hx, right after FlxGame is new'd
 *  since it's a Sprite rather than Flixel related object
 */
class FunkinSoundTray extends FlxSoundTray
{
  static final GRAPHIC_SCALE:Float = 0.30;
  static final BAR_COUNT:Int = 10;
  static final BACKING_BAR_OPACITY:Float = 0.4;

  var lerpYPos:Float = 0;
  var alphaTarget:Float = 0;
  var volumeMaxSound:String;

  public function new()
  {
    // calls super, then removes all children to add our own
    // graphics
    super();
    removeChildren();

    var bg:Bitmap = new Bitmap(Assets.getBitmapData(Paths.image('ui/soundtray/volume-box')));
    bg.scaleX = GRAPHIC_SCALE;
    bg.scaleY = GRAPHIC_SCALE;
    bg.smoothing = true;
    addChild(bg);

    y = -height;
    visible = false;

    // makes an alpha'd version of all the bars (bar_10.png)
    var backingBar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.image('ui/soundtray/bars-10')));
    backingBar.x = 9;
    backingBar.y = 5;
    backingBar.scaleX = GRAPHIC_SCALE;
    backingBar.scaleY = GRAPHIC_SCALE;
    backingBar.smoothing = true;
    addChild(backingBar);
    backingBar.alpha = BACKING_BAR_OPACITY;

    // clear the bars array entirely, it was initialized
    // in the super class
    _bars = [];

    final BAR_X_POS:Int = 9;
    final BAR_Y_POS:Int = 5;

    for (i in 1...(BAR_COUNT + 1))
    {
      var bar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.image('ui/soundtray/bars-${('$i'.lpad('0', 2))}')));
      bar.x = BAR_X_POS;
      bar.y = BAR_Y_POS;
      bar.scaleX = GRAPHIC_SCALE;
      bar.scaleY = GRAPHIC_SCALE;
      bar.smoothing = true;
      addChild(bar);
      _bars.push(bar);
    }

    screenCenter();
    y = -height - 10;

    volumeUpSound = Paths.sound('ui/soundtray/volume-up').toFlxSoundAsset();
    volumeDownSound = Paths.sound('ui/soundtray/volume-down').toFlxSoundAsset();
    volumeMaxSound = Paths.sound('ui/soundtray/volume-max').toFlxSoundAsset();
  }

  override public function update(ms:Float):Void
  {
    var elapsed = ms / Constants.MS_PER_SEC;

    // If it has volume, we want to auto-hide after 1 second (1000ms), we simply decrement a timer
    var hasVolume:Bool = (!FlxG.sound.muted && FlxG.sound.volume > 0);

    if (hasVolume)
    {
      // Animate sound tray thing
      if (_timer > 0)
      {
        _timer -= elapsed;
        if (_timer <= 0)
        {
          lerpYPos = -height - 10;
          alphaTarget = 0;
        }
      }
      else if (y <= -height)
      {
        visible = false;
        active = false;
      }
    }
    else if (!visible)
    {
      showTray();
    }

    y = MathUtil.smoothLerpPrecision(y, lerpYPos, elapsed, 0.768);
    alpha = MathUtil.smoothLerpPrecision(alpha, alphaTarget, elapsed, 0.307);
    screenCenter();
  }

  override function showIncrement():Void
  {
    moveTrayMakeVisible(true);
    saveVolumePreferences();
  }

  override function showDecrement():Void
  {
    moveTrayMakeVisible(false);
    saveVolumePreferences();
  }

  function moveTrayMakeVisible(up:Bool = false):Void
  {
    showTray();

    if (!silent)
    {
      // This is a String currently, but there is or was a Flixel PR to change this to a FlxSound or a Sound bject
      var sound:Null<String> = FlxG.sound.volume == 1 ? volumeMaxSound : (up ? volumeUpSound : volumeDownSound);
      if (sound != null) FlxG.sound.play(sound);
    }
  }

  function showTray():Void
  {
    _timer = 1;
    lerpYPos = 10;
    visible = true;
    active = true;
    alphaTarget = 1;

    updateBars();
  }

  function updateBars():Void
  {
    var globalVolume:Int = FlxG.sound.muted || FlxG.sound.volume == 0 ? 0 : Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);

    for (i in 0..._bars.length) _bars[i].visible = i < globalVolume;
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
