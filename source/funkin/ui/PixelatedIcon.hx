package funkin.ui;

import funkin.graphics.FunkinSprite;
import funkin.assets.Paths;
import funkin.assets.Assets;

/**
 * The icon that gets used for Freeplay capsules and char select
 * NOT to be confused with the HealthIcon class, which is for the in-game icons
 */
@:nullSafety
class PixelatedIcon extends FunkinSprite
{
  public var char:String;

  public static function queryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    var results:Array<funkin.assets.Paths.AssetPath> = [];

    switch (type)
    {
      case IMAGE:
        results.append(Assets.listInPath('ui/freeplay/characters/', IMAGE));
      case XML:
        results.append(Assets.listInPath('ui/freeplay/characters/', XML));
      default:
        // Nothing
    }

    return results;
  }

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

    var charPath:String = 'ui/freeplay/characters/';

    var charIDParts:Array<String> = char.split('-');
    var iconName:String = '';
    var lastValidIconName:String = '';
    for (i in 0...charIDParts.length)
    {
      iconName += charIDParts[i];

      if (Paths.image(charPath + '${iconName}', false).exists())
      {
        lastValidIconName = iconName;
      }

      if (i < charIDParts.length - 1) iconName += '-';
    }

    charPath += '${lastValidIconName}';

    if (lastValidIconName == '' || !Assets.exists(Paths.image(charPath).toString()))
    {
      trace(' WARNING '.warning() + ' Character ${char} has no freeplay icon.');
      this.visible = false;
      return;
    }

    this.visible = true;
    this.char = char; // if we went past this its safe to assume the icon exists so we can assign it

    var isAnimated = Assets.exists(Paths.xml(charPath).toString());

    if (isAnimated)
    {
      this.frames = Paths.getSparrowAtlas(charPath);
    }
    else
    {
      this.loadGraphic(Paths.image(charPath).toFlxGraphicAsset());
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

      this.animation.onFinish.add(function(name:String):Void
      {
        if (name == 'confirm') this.animation.play('confirm-hold');
      });

      this.animation.play('idle');
    }
  }
}
