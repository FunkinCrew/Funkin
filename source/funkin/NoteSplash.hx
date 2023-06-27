package funkin;

import flixel.FlxSprite;
import haxe.io.Path;
import flixel.graphics.frames.FlxAtlasFrames;

class NoteSplash extends FlxSprite
{
  public function new(x:Float, y:Float, noteData:Int = 0):Void
  {
    super(x, y);

    animation.addByPrefix('note0-0', 'note impact 1 purple', 24, false);
    animation.addByPrefix('note1-0', 'note impact 1  blue', 24, false);
    animation.addByPrefix('note2-0', 'note impact 1 green', 24, false);
    animation.addByPrefix('note3-0', 'note impact 1 red', 24, false);
    animation.addByPrefix('note0-1', 'note impact 2 purple', 24, false);
    animation.addByPrefix('note1-1', 'note impact 2 blue', 24, false);
    animation.addByPrefix('note2-1', 'note impact 2 green', 24, false);
    animation.addByPrefix('note3-1', 'note impact 2 red', 24, false);

    setupNoteSplash(x, y, noteData);

    // alpha = 0.75;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (animation.finished)
    {
      kill();
    }
  }

  public static function buildSplashFrames(force:Bool = false):FlxAtlasFrames
  {
    // static variables inside functions are a cool of Haxe 4.3.0.
    static var splashFrames:FlxAtlasFrames = null;

    if (splashFrames != null && !force) return splashFrames;

    splashFrames = Paths.getSparrowAtlas('noteSplashes');

    splashFrames.parent.persist = true;

    return splashFrames;
  }

  public function setupNoteSplash(x:Float, y:Float, noteData:Int = 0)
  {
    setPosition(x, y);
    alpha = 0.6;

    animation.play('note' + noteData + '-' + FlxG.random.int(0, 1), true);
    animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
    animation.finishCallback = function(name) {
      kill();
    };
    updateHitbox();

    offset.set(width * 0.3, height * 0.3);
  }
}
