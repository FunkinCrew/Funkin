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

  public var holdNote:SustainTrail;

  var glow:FlxSprite;
  var sparks:FlxSprite;

  public function new()
  {
    super(0, 0);

    setup();
  }

  public static function preloadFrames():Void
  {
    glowFrames = Paths.getSparrowAtlas('holdCoverRed');
    glowFrames.parent.persist = true;
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

    glow.animation.addByPrefix('holdCoverStartRed', 'holdCoverStartRed0', FRAMERATE_DEFAULT, false, false, false);
    glow.animation.addByPrefix('holdCoverRed', 'holdCoverRed0', FRAMERATE_DEFAULT, true, false, false);
    glow.animation.addByPrefix('holdCoverEndRed', 'holdCoverEndRed0', FRAMERATE_DEFAULT, false, false, false);

    glow.animation.finishCallback = this.onAnimationFinished;

    if (glow.animation.getAnimationList().length < 3)
    {
      trace('WARNING: NoteHoldCover failed to initialize all animations.');
    }
  }

  public override function update(elapsed):Void
  {
    super.update(elapsed);
    if ((!holdNote.alive || holdNote.missedNote) && !glow.animation.curAnim.name.startsWith('holdCoverEnd'))
    {
      // If alive is false, the hold note was held to completion.
      // If missedNote is true, the hold note was "dropped".

      playEnd();
    }
  }

  public function playStart():Void
  {
    // glow.animation.play('holdCoverStart${noteDirection.colorName.toTitleCase()}');
    glow.animation.play('holdCoverStartRed');
  }

  public function playContinue():Void
  {
    // glow.animation.play('holdCover${noteDirection.colorName.toTitleCase()}');
    glow.animation.play('holdCoverRed');
  }

  public function playEnd():Void
  {
    // glow.animation.play('holdCoverEnd${noteDirection.colorName.toTitleCase()}');
    glow.animation.play('holdCoverEndRed');
  }

  public override function kill():Void
  {
    super.kill();

    this.visible = false;

    if (glow != null) glow.visible = false;
    if (sparks != null) sparks.visible = false;
  }

  public override function revive():Void
  {
    super.revive();

    this.visible = true;
    this.alpha = 1.0;

    if (glow != null) glow.visible = true;
    if (sparks != null) sparks.visible = true;
  }

  public function onAnimationFinished(animationName:String):Void
  {
    if (animationName.startsWith('holdCoverStart'))
    {
      playContinue();
    }
    if (animationName.startsWith('holdCoverEnd'))
    {
      // *lightning* *zap* *crackle*
      this.visible = false;
      this.kill();
    }
  }
}
