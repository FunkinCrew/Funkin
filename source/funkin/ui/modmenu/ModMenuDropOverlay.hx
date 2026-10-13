package funkin.ui.modmenu;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;

class ModMenuDropOverlay
{
  static inline final SHOW_DURATION:Float = 0.5;
  static inline final HIDE_DURATION:Float = -0.08;
  static inline final DARKNESS_MAX_ALPHA:Float = 0.72;
  static inline final DARKNESS_Z_INDEX:Int = 3000;

  public var isHovering(default, null):Bool = false;
  public var topZIndex(get, never):Int;

  function get_topZIndex():Int
  {
    return dropTarget.zIndex;
  }

  var darkness:FunkinSprite;
  var dropTarget:FunkinSprite;
  var duration:Float = SHOW_DURATION;
  var elapsed:Float = 0;
  var animDone:Bool = true;

  public function new()
  {
    // poop
  }

  public function build(state:FlxState, camera:FlxCamera):Void
  {
    darkness = new FunkinSprite();
    darkness.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    darkness.scrollFactor.set(0, 0);
    darkness.alpha = 0;
    darkness.visible = false;
    darkness.zIndex = DARKNESS_Z_INDEX;
    darkness.camera = camera;
    state.add(darkness);

    dropTarget = new FunkinSprite().loadTexture('ui/mods/drop-hover');
    dropTarget.setGraphicSize(FlxG.width * 0.95, FlxG.height * 0.9);
    dropTarget.scrollFactor.set(0, 0);
    dropTarget.updateHitbox();
    dropTarget.x = FlxG.width / 2 - (dropTarget.width / 2);
    dropTarget.y = FlxG.height / 2 - (dropTarget.height / 2);
    dropTarget.visible = false;
    dropTarget.zIndex = darkness.zIndex + 1;
    dropTarget.camera = camera;
    state.add(dropTarget);
  }

  public function show():Void
  {
    isHovering = true;
    duration = SHOW_DURATION;
    elapsed = 0;
    animDone = false;

    dropTarget.visible = true;
    darkness.visible = true;
    darkness.alpha = 0;
    dropTarget.alpha = 0;
  }

  public function hide():Void
  {
    isHovering = false;
    duration = HIDE_DURATION;
    elapsed = 0;
    animDone = false;
  }

  public function update(delta:Float):Void
  {
    if (animDone) return;

    elapsed += delta;
    var t = elapsed / duration;

    var adjustT = t;
    if (adjustT < 0) adjustT += 1;

    if (t > 1)
    {
      t = 1;
      animDone = true;
    }
    else if (t < -1)
    {
      t = -1;
      animDone = true;

      dropTarget.visible = false;
      darkness.visible = false;
    }

    dropTarget.alpha = FlxMath.lerp(0, 1, FlxEase.backOut(adjustT));
    darkness.alpha = FlxMath.lerp(0, DARKNESS_MAX_ALPHA, FlxEase.backOut(adjustT));
  }
}
