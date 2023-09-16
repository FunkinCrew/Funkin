package funkin.graphics.framebuffer;

import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import openfl.Lib;
import openfl.display3D.textures.TextureBase;

class FrameBuffer
{
  /**
   * The bitmap data of the frame buffer.
   */
  public var bitmap(default, null):BitmapData = null;

  var texture:TextureBase;
  final camera:FlxCamera;
  final spriteCopies:Array<SpriteCopy> = [];

  public function new()
  {
    camera = new FlxCamera();
    camera.bgColor = FlxColor.TRANSPARENT;
    camera.flashSprite.cacheAsBitmap = true;
  }

  /**
   * Creates a frame buffer with the given size.
   * @param width the width
   * @param height the height
   */
  public function create(width:Int, height:Int):Void
  {
    dispose();
    final c3d = Lib.current.stage.context3D;
    texture = c3d.createTexture(width, height, BGRA, true);
    bitmap = BitmapData.fromTexture(texture);
  }

  /**
   * Makes the internal camera follows the target camera.
   * @param target the target camera
   */
  public function follow(target:FlxCamera):Void
  {
    camera.scroll.copyFrom(target.scroll);
    camera.setScale(target.scaleX, target.scaleY);
  }

  /**
   * Locks the frame buffer and clears the buffer.
   */
  @:access(flixel.FlxCamera)
  public function lock():Void
  {
    camera.clearDrawStack();
    camera.canvas.graphics.clear();
    camera.fill(camera.bgColor.to24Bit(), camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
  }

  /**
   * Renders all sprite copies.
   */
  public function render():Void
  {
    for (spriteCopy in spriteCopies)
    {
      spriteCopy.render(camera);
    }
  }

  /**
   * Unlocks the frame buffer and makes the bitmap ready to use.
   */
  @:access(flixel.FlxCamera)
  public function unlock():Void
  {
    bitmap.fillRect(new Rectangle(0, 0, bitmap.width, bitmap.height), 0);
    bitmap.draw(camera.flashSprite, new Matrix(1, 0, 0, 1, camera.flashSprite.x, camera.flashSprite.y));
  }

  public function dispose():Void
  {
    if (texture != null)
    {
      texture.dispose();
      texture = null;
      bitmap.dispose();
      bitmap = null;
    }
  }

  public function addSpriteCopy(spriteCopy:SpriteCopy):Void
  {
    spriteCopies.push(spriteCopy);
  }
}
