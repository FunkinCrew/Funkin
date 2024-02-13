package funkin.graphics.framebuffer;

import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

/**
 * A single frame buffer. Used by `FrameBufferManager`.
 */
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
    camera.antialiasing = false;
    camera.bgColor = FlxColor.TRANSPARENT;
    @:privateAccess camera.flashSprite.stage = Lib.current.stage;
  }

  /**
   * Creates a frame buffer with the given size.
   * @param width the width
   * @param height the height
   * @param bgColor the background color
   */
  public function create(width:Int, height:Int, bgColor:FlxColor):Void
  {
    dispose();
    texture = Lib.current.stage.context3D.createTexture(width, height, BGRA, true);
    bitmap = FixedBitmapData.fromTexture(texture);
    camera.bgColor = bgColor;
  }

  /**
   * Makes the internal camera follows the target camera.
   * @param target the target camera
   */
  public function follow(target:FlxCamera):Void
  {
    camera.x = target.x;
    camera.y = target.y;
    camera.width = target.width;
    camera.height = target.height;
    camera.scroll.x = target.scroll.x;
    camera.scroll.y = target.scroll.y;
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
    #if FLX_DEBUG
    camera.debugLayer.graphics.clear();
    #end
  }

  /**
   * Renders all sprite copies.
   */
  @:access(flixel.FlxCamera)
  public function render():Void
  {
    for (spriteCopy in spriteCopies)
    {
      spriteCopy.render(camera);
    }
    camera.render();
  }

  /**
   * Unlocks the frame buffer and makes the bitmap ready to use.
   */
  public function unlock():Void
  {
    bitmap.fillRect(new Rectangle(0, 0, bitmap.width, bitmap.height), 0);
    bitmap.draw(camera.flashSprite, new Matrix(1, 0, 0, 1, camera.flashSprite.x, camera.flashSprite.y));
  }

  /**
   * Diposes stuff. Call `create` again if you want to reuse the instance.
   */
  public function dispose():Void
  {
    if (texture != null)
    {
      texture.dispose();
      texture = null;
      bitmap.dispose();
      bitmap = null;
    }
    spriteCopies.resize(0);
  }

  /**
   * Adds a sprite copy to the frame buffer.
   * @param spriteCopy the sprite copy
   */
  public function addSpriteCopy(spriteCopy:SpriteCopy):Void
  {
    spriteCopies.push(spriteCopy);
  }

  /**
   * Adds the sprite to the frame buffer. The sprite will only be seen from
   * the frame buffer.
   * @param sprite the sprite
   */
  public function moveSprite(sprite:FlxSprite):Void
  {
    sprite.cameras = [camera];
  }
}
