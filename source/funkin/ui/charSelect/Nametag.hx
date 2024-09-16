package funkin.ui.charSelect;

import flixel.FlxSprite;
import funkin.graphics.shaders.MosaicEffect;
import flixel.util.FlxTimer;

class Nametag extends FlxSprite
{
  var midpointX(default, set):Float = 1008;
  var midpointY(default, set):Float = 100;
  var mosaicShader:MosaicEffect;

  public function new(?x:Float = 0, ?y:Float = 0)
  {
    super(x, y);

    mosaicShader = new MosaicEffect();
    shader = mosaicShader;

    switchChar("bf");

    FlxG.debugger.addTrackerProfile(new TrackerProfile(Nametag, ["midpointX", "midpointY"]));
    FlxG.debugger.track(this, "Nametag");
  }

  public function updatePosition():Void
  {
    var offsetX:Float = getMidpoint().x - midpointX;
    var offsetY:Float = getMidpoint().y - midpointY;

    x -= offsetX;
    y -= offsetY;
  }

  public function switchChar(str:String):Void
  {
    shaderEffect();

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
      shaderEffect(true);
    });
  }

  function shaderEffect(fadeOut:Bool = false):Void
  {
    if (fadeOut)
    {
      setBlockTimer(0, 1, 1);
      setBlockTimer(1, width / 27, height / 26);
      setBlockTimer(2, width / 10, height / 10);

      setBlockTimer(3, 1, 1);
    }
    else
    {
      setBlockTimer(0, (width / 10), (height / 10));
      setBlockTimer(1, width / 73, height / 6);
      setBlockTimer(2, width / 10, height / 10);
    }
  }

  function setBlockTimer(frame:Int, ?forceX:Float, ?forceY:Float)
  {
    var daX:Float = 10 * FlxG.random.int(1, 4);
    var daY:Float = 10 * FlxG.random.int(1, 4);

    if (forceX != null) daX = forceX;

    if (forceY != null) daY = forceY;

    new FlxTimer().start(frame / 30, _ -> {
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
