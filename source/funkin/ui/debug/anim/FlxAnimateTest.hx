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

    sprite = new FlxAtlasSprite(0, 0, 'shared:assets/shared/images/characters/tankman');
    add(sprite);

    sprite.playAnimation('idle');
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.SPACE) sprite.playAnimation('idle');

    if (FlxG.keys.justPressed.W) sprite.playAnimation('singUP');

    if (FlxG.keys.justPressed.A) sprite.playAnimation('singLEFT');

    if (FlxG.keys.justPressed.S) sprite.playAnimation('singDOWN');

    if (FlxG.keys.justPressed.D) sprite.playAnimation('singRIGHT');

    if (FlxG.keys.justPressed.J) sprite.playAnimation('hehPrettyGood');

    if (FlxG.keys.justPressed.K) sprite.playAnimation('ugh');
  }
}
