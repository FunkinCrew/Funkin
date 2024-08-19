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

    sprite = new FlxAtlasSprite(0, 0, 'assets/images/freeplay/freeplay-boyfriend'); // I suppose a specific atlas to test should go in here

    add(sprite);
    sprite.anim.play("Boyfriend DJ");
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }
}
