package funkin.play.notes;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.play.notes.NoteDirection;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;

class NoteHoldCover extends FlxTypedSpriteGroup<FlxSprite>
{
  static final FRAMERATE_DEFAULT:Int = 24;

  static var glowFrames:FlxAtlasFrames;

  var glow:FlxSprite;
  var sparks:FlxSprite;

  public static function preloadFrames():Void
  {
    glowFrames = Paths.getSparrowAtlas('holdCoverRed');
  }

  public function new()
  {
    super(0, 0);

    setup();
  }

  /**
   * Add ALL the animations to this sprite. We will recycle and reuse the FlxSprite multiple times.
   */
  function setup():Void
  {
    glow = new FlxSprite();
    add(glow);
    if (glowFrames == null) preloadFrames();
    glow.frames = glowFrames;

    glow.animation.addByPrefix('holdCoverRed', 'holdCoverRed0', FRAMERATE_DEFAULT, true, false, false);
    glow.animation.addByPrefix('holdCoverEndRed', 'holdCoverEndRed0', FRAMERATE_DEFAULT, true, false, false);

    glow.animation.finishCallback = this.onAnimationFinished;

    if (glow.animation.getAnimationList().length < 2)
    {
      trace('WARNING: NoteHoldCover failed to initialize all animations.');
    }
  }

  public function playStart(direction:NoteDirection):Void
  {
    glow.animation.play('holdCoverRed');
  }

  public function playContinue(direction:NoteDirection):Void
  {
    glow.animation.play('holdCoverRed');
  }

  public function playEnd(direction:NoteDirection):Void
  {
    glow.animation.play('holdCoverEndRed');
  }

  public function onAnimationFinished(animationName:String):Void
  {
    if (animationName.startsWith('holdCoverEnd'))
    {
      // *lightning* *zap* *crackle*
      this.kill();
    }
  }
}
