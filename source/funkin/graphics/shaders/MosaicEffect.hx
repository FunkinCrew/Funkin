package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.math.FlxPoint;

@:nullSafety
class MosaicEffect extends FlxRuntimeShader
{
  public var blockSize:FlxPoint = FlxPoint.get(1.0, 1.0);

  public function new()
  {
    super(Assets.getText(Paths.frag('mosaic')));
    setBlockSize(1.0, 1.0);
  }

  public function setBlockSize(w:Float, h:Float)
  {
    blockSize.set(w, h);
    setFloatArray("uBlocksize", [w, h]);
  }
}
