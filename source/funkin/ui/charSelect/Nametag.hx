package funkin.ui.charSelect;

import flixel.FlxSprite;
import funkin.graphics.shaders.MosaicEffect;
import flixel.util.FlxTimer;
import funkin.util.TimerUtil;

class Nametag extends FlxSprite
{
  @:allow(funkin.ui.charSelect.CharSelectSubState)
  var midpointX(default, set):Float = 1008;
  @:allow(funkin.ui.charSelect.CharSelectSubState)
  var midpointY(default, set):Float = 100;
  var mosaicShader:MosaicEffect;

  var currentMosaicSequence:Sequence;

  public function new(?x:Float = 0, ?y:Float = 0, character:String)
  {
    super(x, y);

    mosaicShader = new MosaicEffect();
    shader = mosaicShader;

    // So that's why there was that cursed sight (originally defaulted to bf)
    // Made it not play the shader effect to prevent its being stuck, can't see it anyway.
    if (character != null) switchChar(character, false);
    else
      switchChar(Constants.DEFAULT_CHARACTER, false);
  }

  public function updatePosition():Void
  {
    var offsetX:Float = getMidpoint().x - midpointX;
    var offsetY:Float = getMidpoint().y - midpointY;

    x -= offsetX;
    y -= offsetY;
  }

  public function switchChar(str:String, playMosaicSequence:Bool = true):Void
  {
    if (playMosaicSequence) shaderEffect();

    new FlxTimer().start(4 / 30, _ -> {
      var path:String = str;
      switch str
      {
        case "bf":
          path = "boyfriend";
      }

      loadGraphic(Paths.image('charSelect/' + path + "Nametag"));
      updateHitbox();
      scale.x = scale.y = 0.77;

      updatePosition();

      if (playMosaicSequence) shaderEffect(true);
    });
  }

  function shaderEffect(fadeOut:Bool = false):Void
  {
    if (currentMosaicSequence != null)
    {
      // Forcibly reset the shader to prevent overlapping blur sequences
      mosaicShader.setBlockSize(1, 1);
      currentMosaicSequence.destroy();
      currentMosaicSequence = null;
    }

    if (fadeOut)
    {
      currentMosaicSequence = new Sequence([
        {time: 0 / 30, callback: () -> mosaicShader.setBlockSize(1, 1)},
        {time: 1 / 30, callback: () -> mosaicShader.setBlockSize(width / 27, height / 26)},
        {time: 2 / 30, callback: () -> mosaicShader.setBlockSize(width / 10, height / 10)},
        {time: 3 / 30, callback: () -> mosaicShader.setBlockSize(1, 1)},
      ]);
    }
    else
    {
      currentMosaicSequence = new Sequence([
        {time: 0 / 30, callback: () -> mosaicShader.setBlockSize(width / 10, height / 10)},
        {time: 1 / 30, callback: () -> mosaicShader.setBlockSize(width / 73, height / 6)},
        {time: 2 / 30, callback: () -> mosaicShader.setBlockSize(width / 10, height / 10)},
      ]);
    }
  }

  function setBlockTimer(frame:Int, ?forceX:Float, ?forceY:Float):Void
  {
    var daX:Float = forceX ?? 10 * FlxG.random.int(1, 4);
    var daY:Float = forceY ?? 10 * FlxG.random.int(1, 4);

    FlxTimer.wait(frame / 30, () -> {
      mosaicShader.setBlockSize(daX, daY);
    });
  }

  function set_midpointX(val:Float):Float
  {
    this.midpointX = val;
    updatePosition();
    return val;
  }

  function set_midpointY(val:Float):Float
  {
    this.midpointY = val;
    updatePosition();
    return val;
  }
}
