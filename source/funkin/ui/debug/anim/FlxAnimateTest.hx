package funkin.ui.debug.anim;

import flixel.FlxG;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.ui.MusicBeatState;

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

    sprite = new FlxAtlasSprite(0, 0, 'assets/images/charSelect/maskTest');
    add(sprite);
    sprite.playAnimation(null, false, false, true);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.SPACE) ((sprite.anim.isPlaying) ? sprite.anim.pause() : sprite.playAnimation(null, false, false, true));

    if (FlxG.keys.anyJustPressed([A, LEFT])) sprite.anim.curFrame--;
    if (FlxG.keys.anyJustPressed([D, RIGHT])) sprite.anim.curFrame++;
  }
}
