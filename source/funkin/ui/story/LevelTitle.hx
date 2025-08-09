package funkin.ui.story;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.util.MathUtil;

@:nullSafety
class LevelTitle extends FlxSpriteGroup
{
  static final LOCK_PAD:Int = 4;

  public final level:Null<Level>;

  public var targetY:Float = 0.00;

  var title:FlxSprite = new FlxSprite();
  var lock:Null<FlxSprite>;

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

    if (lock != null && lock.visible)
    {
      return title.width + lock.width + LOCK_PAD;
    }
    else
    {
      if (title != null)
      {
        return title.width;
      } else {
        return 0;
      }
    }
  }

  public var isFlashing:Bool = false;

  var flashTick:Float = 0;
  final flashFramerate:Float = 20;

  public override function update(elapsed:Float):Void
  {
    this.y = MathUtil.smoothLerpPrecision(y, targetY, elapsed, 0.451);

    if (isFlashing)
    {
      flashTick += elapsed;
      if (flashTick >= 1 / flashFramerate)
      {
        flashTick %= 1 / flashFramerate;
        title.color = (title?.color == FlxColor.WHITE) ? 0xFF33ffff : FlxColor.WHITE;
      }
    }
  }

  public function showLock():Void
  {
    if (lock != null)
    {
      lock.visible = true;
      this.x -= (lock.width + LOCK_PAD) / 2;
    } 
  }

  public function hideLock():Void
  {
    if (lock != null) 
    {
      lock.visible = false;
      this.x += (lock.width + LOCK_PAD) / 2;
    }
  }

  function buildLevelTitle():Void
  {
    if (title != null && level != null) 
    {
      title = level.buildTitleGraphic();
      add(title);
    }
  }

  function buildLevelLock():Void
  {
    lock = new FlxSprite(0, 0).loadGraphic(Paths.image('storymenu/ui/lock'));
    lock.x = title.x + title.width + LOCK_PAD;
    lock.visible = false;
    add(lock);
  }
}
