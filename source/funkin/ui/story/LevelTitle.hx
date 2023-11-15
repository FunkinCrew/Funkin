package funkin.ui.story;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.util.MathUtil;

class LevelTitle extends FlxSpriteGroup
{
  static final LOCK_PAD:Int = 4;

  public final level:Level;

  public var targetY:Float;
  public var isFlashing:Bool = false;

  var title:FlxSprite;
  var lock:FlxSprite;

  var flashingInt:Int = 0;

  public function new(x:Int, y:Int, level:Level)
  {
    super(x, y);

    this.level = level;

    if (this.level == null) throw "Level cannot be null!";

    buildLevelTitle();
    buildLevelLock();
  }

  override function get_width():Float
  {
    if (length == 0) return 0;

    if (lock.visible)
    {
      return title.width + lock.width + LOCK_PAD;
    }
    else
    {
      return title.width;
    }
  }

  // if it runs at 60fps, fake framerate will be 6
  // if it runs at 144 fps, fake framerate will be like 14, and will update the graphic every 0.016666 * 3 seconds still???
  // so it runs basically every so many seconds, not dependant on framerate??
  // I'm still learning how math works thanks whoever is reading this lol
  var fakeFramerate:Int = Math.round((1 / FlxG.elapsed) / 10);

  public override function update(elapsed:Float):Void
  {
    this.y = MathUtil.coolLerp(y, targetY, 0.17);

    if (isFlashing) flashingInt += 1;
    if (flashingInt % fakeFramerate >= Math.floor(fakeFramerate / 2)) title.color = 0xFF33ffff;
    else
      title.color = FlxColor.WHITE;
  }

  public function showLock():Void
  {
    lock.visible = true;
    this.x -= (lock.width + LOCK_PAD) / 2;
  }

  public function hideLock():Void
  {
    lock.visible = false;
    this.x += (lock.width + LOCK_PAD) / 2;
  }

  function buildLevelTitle():Void
  {
    title = level.buildTitleGraphic();
    add(title);
  }

  function buildLevelLock():Void
  {
    lock = new FlxSprite(0, 0).loadGraphic(Paths.image('storymenu/ui/lock'));
    lock.x = title.x + title.width + LOCK_PAD;
    lock.visible = false;
    add(lock);
  }
}
