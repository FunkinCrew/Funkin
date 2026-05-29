package funkin.ui.charSelect.characters;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.MosaicEffect;
import funkin.util.TimerUtil.Sequence;

/**
 * The nametag that appears at the top right of the Character Select screen.
 */
@:nullSafety
class Nametag extends FunkinSprite
{
  /**
   * The target position of the nametag.
   */
  public var targetPosition:FlxPoint = FlxPoint.get(1008, 100);

  var mosaicShader:MosaicEffect;
  var currentMosaicSequence:Null<Sequence>;

  public function new(?x:Float = 0, ?y:Float = 0, character:String)
  {
    super(x, y);

    mosaicShader = new MosaicEffect();
    shader = mosaicShader;

    loadCharacter(character, false);
  }

  override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    var position:FlxPoint = super.getScreenPosition(result, camera);
    var originalMidpoint:FlxPoint = getMidpoint();
    var offset:FlxPoint = originalMidpoint - targetPosition;

    originalMidpoint.put();
    position -= offset;
    offset.put();

    return position;
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

  /**
   * Loads a new nametag graphic based on the given character ID.
   * @param characterId The character ID to load.
   * @param playMosaicSequence Whether to play the mosaic sequence.
   */
  public function loadCharacter(characterId:String, playMosaicSequence:Bool = true):Void
  {
    loadGraphic(Paths.image('ui/character-select/characters/nametag-$characterId'));
    updateHitbox();
    scale.set(0.77, 0.77);
    scrollFactor.set();

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
        {
          time: 3 / 30,
          callback: () -> mosaicShader.setBlockSize(1, 1)
        },
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
        {
          time: 2 / 30,
          callback: () -> mosaicShader.setBlockSize(width / 10, height / 10)
        },
      ]);
    }
  }
}
