package funkin.ui.debug.anim;

import flixel.FlxG;
import funkin.graphics.FunkinSprite;
import funkin.ui.MusicBeatState;
import funkin.util.macro.ConsoleMacro;
import funkin.Paths;

/**
 * A simple test of FlxAnimate.
 * Delete this later?
 */
class FlxAnimateTest extends MusicBeatState implements ConsoleClass
{
  var sprite:FunkinSprite;

  public function new()
  {
    super();
    this.bgColor = 0xFF999999;
  }

  public override function create():Void
  {
    super.create();

    sprite = FunkinSprite.createTextureAtlas(0, 0, "charSelect/bfChill",
      {
        swfMode: false, // If to render like in a SWF file, rather than the Animate editor.
        cacheOnLoad: true, // If to precache all animation filters and masks at once, rather than at runtime.
        filterQuality: MEDIUM // Level of quality used to render filters. (HIGH, MEDIUM, LOW, RUDY)
      });

    add(sprite);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.SPACE) (!(sprite.isAnimationFinished()) ? sprite.anim.pause() : sprite.anim.resume());

    if (FlxG.keys.anyJustPressed([A, LEFT])) sprite.anim.curAnim.curFrame--;
    if (FlxG.keys.anyJustPressed([D, RIGHT])) sprite.anim.curAnim.curFrame++;

    if (FlxG.keys.justPressed.Q) sprite.anim.play("slidein idle point", true);
    if (FlxG.keys.justPressed.W) sprite.anim.play("slidein", true);
    if (FlxG.keys.justPressed.E) sprite.anim.play("death", true);
    if (FlxG.keys.justPressed.R) sprite.anim.play("cannot select Label", true);
    if (FlxG.keys.justPressed.T) sprite.anim.play("idle", true);
  }
}
