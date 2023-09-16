package funkin;

import flixel.FlxSprite;

/**
 * Provides a clone of a sprite that is filled with a single color while keeping its alpha.
 */
class SolidColorSprite extends FlxSprite
{
  /**
   * The FlxSprite that this sprite referes to.
   */
  public var reference:FlxSprite;

  /**
   * The red color strength, from 0.0 to 1.0.
   */
  public var red:Float;

  /**
   * The green color strength, from 0.0 to 1.0.
   */
  public var green:Float;

  /**
   * The blue color strength, from 0.0 to 1.0.
   */
  public var blue:Float;

  function new(reference:FlxSprite, red:Float = 1.0, green:Float = 1.0, blue:Float = 1.0)
  {
    super();
    this.reference = reference;
    this.red = red;
    this.green = green;
    this.blue = blue;
  }

  override function draw():Void
  {
    super.draw();

    final rMult = reference.colorTransform.redMultiplier;
    final gMult = reference.colorTransform.greenMultiplier;
    final bMult = reference.colorTransform.blueMultiplier;
    final aMult = reference.colorTransform.alphaMultiplier;
    final rOff = Std.int(reference.colorTransform.redOffset);
    final gOff = Std.int(reference.colorTransform.greenOffset);
    final bOff = Std.int(reference.colorTransform.blueOffset);
    final aOff = Std.int(reference.colorTransform.alphaOffset);
    final tmpCameras = reference._cameras;
    final tmpShader = reference.shader;

    reference._cameras = _cameras;

    reference.shader = shader;
    reference.setColorTransform(0, 0, 0, 1, Std.int(red * 255 + 0.5), Std.int(green * 255 + 0.5), Std.int(blue * 255 + 0.5), 0);
    reference.draw();

    reference._cameras = tmpCameras;
    reference.shader = tmpShader;
    reference.setColorTransform(rMult, gMult, bMult, aMult, rOff, gOff, bOff, aOff);
  }
}
