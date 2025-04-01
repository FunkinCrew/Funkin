package funkin.ui;

import flixel.FlxSprite;
import funkin.graphics.FlxFilteredSprite;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;

/**
 * The icon that gets used for Freeplay capsules and char select
 * NOT to be confused with the CharIcon class, which is for the in-game icons
 */
class PixelatedIcon extends FlxFilteredSprite
{
  public function new(x:Float, y:Float)
  {
    super(x, y);

    this.makeGraphic(32, 32, 0x00000000);
    this.antialiasing = false;
    this.active = false;
  }

  public function setCharacter(char:String):Void
  {
    var charPath:String = "freeplay/icons/";
    var charPixelIconData = CharacterDataParser.getCharPixelIconData(char);

    if (charPixelIconData == null)
    {
      trace('[WARN] Character ${char} has no pixel icon data.');
      return;
    }

    charPath += '${charPixelIconData.id}pixel';

    if (!openfl.utils.Assets.exists(Paths.image(charPath)))
    {
      trace('[WARN] Character ${char} has no freeplay icon.');
      this.visible = false;
      return;
    }
    else
    {
      this.visible = true;
    }

    var isAnimated = openfl.utils.Assets.exists(Paths.file('images/$charPath.xml'));

    if (isAnimated)
    {
      this.frames = Paths.getSparrowAtlas(charPath);
    }
    else
    {
      this.loadGraphic(Paths.image(charPath));
    }

    this.scale.x = this.scale.y = 2;

    // Set to 100 for default position
    this.origin.x = 100;

    // Add the pixel icon origin with offsets for position adjustments
    this.origin.x += charPixelIconData.originOffsets[0];
    this.origin.y += charPixelIconData.originOffsets[1];
    // Set whether or not to flip the pixel icon
    this.flipX = charPixelIconData.flipX;

    if (isAnimated)
    {
      this.active = true;
      this.animation.addByPrefix('idle', 'idle0', 10, true);
      this.animation.addByPrefix('confirm', 'confirm0', 10, false);
      this.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);

      this.animation.finishCallback = function(name:String):Void {
        trace('Finish pixel animation: ${name}');
        if (name == 'confirm') this.animation.play('confirm-hold');
      };

      this.animation.play('idle');
    }
  }
}
