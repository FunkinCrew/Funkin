package funkin.ui.charSelect;

import flixel.FlxSprite;
import funkin.graphics.shaders.MosaicEffect;
import flixel.util.FlxTimer;
import funkin.util.TimerUtil;
import flixel.math.FlxPoint;

@:nullSafety
class Nametag extends FlxSprite
{
  public var midpoint(default, set):FlxPoint = FlxPoint.get(1008, 100);

  var mosaicShader:MosaicEffect;
  var currentMosaicSequence:Null<Sequence>;

  public function new(?x:Float = 0, ?y:Float = 0, character:String)
  {
    super(x, y);

    mosaicShader = new MosaicEffect();
    shader = mosaicShader;

    // So that's why there was that cursed sight (originally defaulted to bf)
    // Made it not play the shader effect to prevent its being stuck, can't see it anyway.
    final targetCharacter = (character != null) ? character : Constants.DEFAULT_CHARACTER;
    switchChar(targetCharacter, false);
  }

  public function updatePosition():Void
  {
    var offsetX:Float = getMidpoint().x - midpoint.x;
    var offsetY:Float = getMidpoint().y - midpoint.y;

    x -= offsetX;
    y -= offsetY;
  }

  function resetMosaicEffect():Void
  {
    if (currentMosaicSequence != null)
    {
      currentMosaicSequence.destroy();

      currentMosaicSequence = null;
    }

    mosaicShader.setBlockSize(1, 1);
  }

  public function switchChar(str:String, playMosaicSequence:Bool = true):Void
  {
    var path:String = (str == "bf") ? "boyfriend" : "bf";
    if (str != "bf") path = str;

    loadGraphic(Paths.image("charSelect/" + path + "Nametag"));
    updateHitbox();
    scale.set(0.77, 0.77);
    updatePosition();

    resetMosaicEffect();

    if (!playMosaicSequence) return;

    shaderEffect();

    // Delay the shader effect by a bit to prevent lag.
    new FlxTimer().start(2 / 30, _ ->
    {
      shaderEffect(true);
    });
  }

  function shaderEffect(fadeOut:Bool = false):Void
  {
    // Skip the shader effect if the width is too small.
    if (width <= 1) return;

    if (fadeOut)
    {
      currentMosaicSequence = new Sequence([
        {
          time: 0 / 30,
          callback: () -> mosaicShader.setBlockSize(1, 1)
        },
        {
          time: 1 / 30,
          callback: () -> mosaicShader.setBlockSize(width / 27, height / 26)
        },
        {
          time: 2 / 30,
          callback: () -> mosaicShader.setBlockSize(width / 10, height / 10)
        },
        {time: 3 / 30, callback: () -> mosaicShader.setBlockSize(1, 1)},
      ]);
    }
    else
    {
      currentMosaicSequence = new Sequence([
        {
          time: 0 / 30,
          callback: () -> mosaicShader.setBlockSize(width / 10, height / 10)
        },
        {
          time: 1 / 30,
          callback: () -> mosaicShader.setBlockSize(width / 73, height / 6)
        },
        {time: 2 / 30, callback: () -> mosaicShader.setBlockSize(width / 10, height / 10)},
      ]);
    }
  }

  function set_midpoint(val:FlxPoint):FlxPoint
  {
    this.midpoint = val;
    updatePosition();
    return val;
  }
}
