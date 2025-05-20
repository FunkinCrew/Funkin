package funkin.ui.freeplay;

import flixel.group.FlxSpriteGroup;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.shaders.HSVShader;

@:nullSafety
class DifficultyStars extends FlxSpriteGroup
{
  /**
   * Internal handler var for difficulty... ranges from 0... to 15
   * 0 is 1 star... 15 is 0 stars!
   */
  var curDifficulty(default, set):Int = 0;

  /**
   * Range between 0 and 15
   */
  public var difficulty(default, set):Int = 1;

  public var stars:FlxAtlasSprite;

  public var flames:FreeplayFlames;

  var hsvShader:HSVShader;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    hsvShader = new HSVShader();

    flames = new FreeplayFlames(0, 0);

    stars = new FlxAtlasSprite(0, 0, Paths.animateAtlas("freeplay/freeplayStars"));
    stars.anim.play("diff stars");

    add(flames);
    add(stars);

    stars.shader = hsvShader;

    for (memb in flames.members)
      memb.shader = hsvShader;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // "loops" the current animation
    // for clarity, the animation file looks like
    // frame : stars
    // 0-99: 1 star
    // 100-199: 2 stars
    // ......
    // 1300-1499: 15 stars
    // 1500 : 0 stars
    if (curDifficulty < 15 && stars.anim.curFrame >= (curDifficulty + 1) * 100)
    {
      stars.anim.play("diff stars", true, false, curDifficulty * 100);
    }
  }

  function set_difficulty(value:Int):Int
  {
    difficulty = value;

    if (difficulty <= 0)
    {
      difficulty = 0;
      curDifficulty = 15;
    }
    else if (difficulty <= 15)
    {
      difficulty = value;
      curDifficulty = difficulty - 1;
    }
    else
    {
      difficulty = 15;
      curDifficulty = difficulty - 1;
    }

    flameCheck();

    return difficulty;
  }

  public function flameCheck():Void
  {
    if (difficulty > 10) flames.flameCount = difficulty - 10;
    else
      flames.flameCount = 0;
  }

  function set_curDifficulty(value:Int):Int
  {
    curDifficulty = value;
    if (curDifficulty == 15)
    {
      stars.anim.play("diff stars", true, false, 1500);
      stars.anim.pause();
    }
    else
    {
      stars.anim.curFrame = Std.int(curDifficulty * 100);
      stars.anim.play("diff stars", true, false, curDifficulty * 100);
    }

    return curDifficulty;
  }
}
