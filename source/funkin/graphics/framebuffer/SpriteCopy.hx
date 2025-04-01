package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 * A copy of a `FlxSprite` with a specified color. Used to render the sprite to a frame buffer.
 */
class SpriteCopy
{
  final sprite:FlxSprite;
  final color:Null<FlxColor>;

  public function new(sprite:FlxSprite, color:Null<FlxColor>)
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
    if (color == null)
    {
      final tmpCameras = sprite._cameras;
      sprite._cameras = [camera];
      sprite.draw();
      sprite._cameras = tmpCameras;
    }
    else
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
      final tmpShader = sprite.shader;

      sprite._cameras = [camera];
      sprite.shader = null;

      sprite.setColorTransform(0, 0, 0, 1, color.red, color.green, color.blue, 0);
      sprite.draw();

      sprite._cameras = tmpCameras;
      sprite.shader = tmpShader;
      sprite.setColorTransform(rMult, gMult, bMult, aMult, rOff, gOff, bOff, aOff);
    }
  }
}
