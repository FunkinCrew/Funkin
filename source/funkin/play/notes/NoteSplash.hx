package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxG;
import flixel.FlxSprite;
import funkin.play.PlayState;

class NoteSplash extends FlxSprite
{
  public var splashFramerate:Int = 24;
  public var splashFramerateVariance:Int = 2;

  public function new(noteStyle:NoteStyle)
  {
    super(0, 0);

    setupSplashGraphic(noteStyle);

    this.animation.onFinish.add(this.onAnimationFinished);
  }

  /**
   * Add ALL the animations to this sprite. We will recycle and reuse the FlxSprite multiple times.
   */
  function setupSplashGraphic(noteStyle:NoteStyle):Void
  {
    if (frames == null)
    {
      noteStyle.buildSplashSprite(this);
      _variantCounts = [-1, -1, -1, -1];
    }

    if (this.animation.getAnimationList().length < 8)
    {
      trace('WARNING: NoteSplash failed to initialize all animations.');
    }
  }

  public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, startFrame:Int = 0):Void
  {
    this.animation.play(name, force, reversed, startFrame);
  }

  public function play(direction:NoteDirection, ?variant:Int):Void
  {
    if (variant == null)
    {
      variant = FlxG.random.int(0, getVariantCount(direction) - 1);
    }

    // splashUP0, splashUP1, splashRIGHT0, etc.
    // the animations are processed via `NoteStyle.fetchSplashAnimationData()` in this format
    this.playAnimation('splash${direction.nameUpper}${variant}');

    if (animation.curAnim == null) return;

    // Vary the speed of the animation a bit.
    animation.curAnim.frameRate = splashFramerate + FlxG.random.int(-splashFramerateVariance, splashFramerateVariance);

    // Center the animation on the note splash.
    offset.set(width * 0.3, height * 0.3);
  }

  var _variantCounts:Array<Int> = [-1, -1, -1, -1];

  function getVariantCount(direction:NoteDirection):Int
  {
    var index:Int = direction % 4;
    var cached:Int = _variantCounts[index];
    if (cached >= 0) return cached;

    var prefix:String = 'splash${direction.nameUpper}';
    var count:Int = 0;
    for (anim in this.animation.getAnimationList())
    {
      if (anim.name.startsWith(prefix)) count++;
    }

    _variantCounts[index] = count;
    return count;
  }

  public function onAnimationFinished(animationName:String):Void
  {
    // *lightning* *zap* *crackle*
    this.kill();
  }
}
