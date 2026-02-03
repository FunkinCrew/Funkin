package funkin.ui;

import funkin.graphics.FlxFilteredSprite;

/**
 * The icon that gets used for Freeplay capsules and char select
 * NOT to be confused with the CharIcon class, which is for the in-game icons
 */
@:nullSafety
class PixelatedIcon extends FlxFilteredSprite
{
  public var char:String;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    this.char = '';

    this.makeGraphic(32, 32, 0x00000000);
    this.antialiasing = false;
    this.active = false;
  }

  public function setCharacter(char:String):Void
  {
    if (this.char == char) return;
    this.char = char;

    var charPath:String = "freeplay/icons/";

    final charIDParts:Array<String> = char.split("-");
    var iconName:String = "";
    var lastValidIconName:String = "";
    for (i in 0...charIDParts.length)
    {
      iconName += charIDParts[i];

      if (Assets.exists(Paths.image(charPath + '${iconName}pixel')))
      {
        lastValidIconName = iconName;
      }

      if (i < charIDParts.length - 1) iconName += '-';
    }

    charPath += '${lastValidIconName}pixel';

    if (!Assets.exists(Paths.image(charPath)))
    {
      trace(' WARNING '.warning() + ' Character ${char} has no freeplay icon.');
      this.visible = false;
      return;
    }
    else
    {
      this.visible = true;
    }

    var isAnimated = Assets.exists(Paths.file('images/$charPath.xml'));

    if (isAnimated)
    {
      this.frames = Paths.getSparrowAtlas(charPath);
    }
    else
    {
      this.loadGraphic(Paths.image(charPath));
    }

    this.scale.x = this.scale.y = 2;

    // TODO: Move this to JSON later!! (This code pisses me off) - Abnormal
    switch (char)
    {
      case 'parents-christmas':
        this.origin.x = 140;
      case 'sserafim-kazuha':
        this.origin.x = 195;
      default:
        this.origin.x = 100;
    }

    if (isAnimated)
    {
      this.active = true;
      this.animation.addByPrefix('idle', 'idle0', 10, true);
      this.animation.addByPrefix('confirm', 'confirm0', 10, false);
      this.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);

      this.animation.onFinish.add(function(name:String):Void {
        if (name == 'confirm') this.animation.play('confirm-hold');
      });

      this.animation.play('idle');
    }
  }
}
