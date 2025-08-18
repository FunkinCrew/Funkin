package funkin.ui.debug.anim;

import flixel.FlxG;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.ui.MusicBeatState;
import funkin.Paths;

/**
 * A simple test of FlxAnimate.
 * Delete this later?
 */
class FlxAnimateTest extends MusicBeatState
{
  var sprite:FlxAtlasSprite;

  public function new()
  {
    super();
    this.bgColor = 0xFF999999;
  }

  public override function create():Void
  {
    super.create();

    sprite = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/lockedChill"),
      {
        swfMode: false, // If to render like in a SWF file, rather than the Animate editor.
        cacheOnLoad: true, // If to precache all animation filters and masks at once, rather than at runtime.
        filterQuality: MEDIUM // Level of quality used to render filters. (HIGH, MEDIUM, LOW, RUDY)
      });

    sprite.anim.addByFrameLabel("slideout", "slideout");
    sprite.anim.addByFrameLabel("slidein", "slidein");
    sprite.anim.addByFrameLabel("death", "death");
    sprite.anim.addByFrameLabel("cannot select label", "cannot select label");

    add(sprite);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.SPACE) (!(sprite.anim.finished) ? sprite.anim.pause() : sprite.anim.resume());

    if (FlxG.keys.anyJustPressed([A, LEFT])) sprite.anim.curAnim.curFrame--;
    if (FlxG.keys.anyJustPressed([D, RIGHT])) sprite.anim.curAnim.curFrame++;

    if (FlxG.keys.justPressed.Q) sprite.playAnimation("slideout", true, false, false);
    if (FlxG.keys.justPressed.W) sprite.playAnimation("slidein", true, false, false);
    if (FlxG.keys.justPressed.E) sprite.playAnimation("death", true, false, false);
    if (FlxG.keys.justPressed.R) sprite.playAnimation("cannot select label", true, false, false);
  }
}
