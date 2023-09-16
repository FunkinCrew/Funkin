package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.FlxSprite;

class SpriteCopy
{
  final sprite:FlxSprite;
  var color:Int;

  public function new(sprite:FlxSprite, color:Int = -1)
  {
    this.sprite = sprite;
    this.color = color;
  }

  /**
   * Renders the copy to the camera.
   * @param camera the camera
   */
  @:access(flixel.FlxSprite)
  public function render(camera:FlxCamera):Void
  {
    final rMult = sprite.colorTransform.redMultiplier;
    final gMult = sprite.colorTransform.greenMultiplier;
    final bMult = sprite.colorTransform.blueMultiplier;
    final aMult = sprite.colorTransform.alphaMultiplier;
    final rOff = Std.int(sprite.colorTransform.redOffset);
    final gOff = Std.int(sprite.colorTransform.greenOffset);
    final bOff = Std.int(sprite.colorTransform.blueOffset);
    final aOff = Std.int(sprite.colorTransform.alphaOffset);
    final tmpCameras = sprite._cameras;

    sprite._cameras = [camera];

    if (color != -1)
    {
      final red = color >> 16 & 0xFF;
      final green = color >> 8 & 0xFF;
      final blue = color & 0xFF;
      sprite.setColorTransform(0, 0, 0, 1, red, green, blue, 0);
    }
    sprite.draw();

    sprite._cameras = tmpCameras;
    if (color != -1)
    {
      sprite.setColorTransform(rMult, gMult, bMult, aMult, rOff, gOff, bOff, aOff);
    }
  }
}
