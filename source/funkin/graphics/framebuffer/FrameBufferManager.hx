package funkin.graphics.framebuffer;

import openfl.display.BitmapData;
import flixel.FlxSprite;
import flixel.FlxCamera;

class FrameBufferManager
{
  final camera:FlxCamera;
  final frameBufferMap:Map<String, FrameBuffer> = [];

  /**
   * Creates a frame buffer manager that targets `camera`.
   * @param camera the target camera.
   */
  public function new(camera:FlxCamera)
  {
    this.camera = camera;
  }

  /**
   * Creates a new frame buffer with a name.
   * @param name the name
   */
  public function createFrameBuffer(name:String):Void
  {
    if (frameBufferMap.exists(name))
    {
      FlxG.log.warn('frame buffer "$name" already exists');
    }
    else
    {
      final fb = new FrameBuffer();
      fb.create(camera.width, camera.height);
      frameBufferMap[name] = fb;
    }
  }

  /**
   * Adds a copy of the sprite to the frame buffer.
   * @param name the name of the frame buffer
   * @param sprite the sprite
   * @param color if this is not `-1`, the sprite will have the color while keeping its shape
   */
  public function addSpriteTo(name:String, sprite:FlxSprite, color:Int = -1):Void
  {
    if (!frameBufferMap.exists(name))
    {
      createFrameBuffer(name);
    }
    frameBufferMap[name].addSpriteCopy(new SpriteCopy(sprite, color));
  }

  /**
   * Call this before everything is drawn.
   */
  public function lock():Void
  {
    for (_ => fb in frameBufferMap)
    {
      fb.lock();
    }
  }

  /**
   * Renders all the copies of the sprites. Make sure this is called between
   * `lock` and `unlock`.
   */
  public function render():Void
  {
    for (_ => fb in frameBufferMap)
    {
      fb.render();
    }
  }

  /**
   * After calling this you can use bitmap data of all frame buffers.
   */
  public function unlock():Void
  {
    for (_ => fb in frameBufferMap)
    {
      fb.unlock();
    }
  }

  /**
   * Returns the bitmap data of the frame buffer
   * @param name the name of the frame buffer
   * @return the ready-to-use bitmap data
   */
  public function getFrameBuffer(name:String):BitmapData
  {
    return frameBufferMap[name].bitmap;
  }

  /**
   * Disposes all frame buffers.
   */
  public function dispose():Void
  {
    for (_ => fb in frameBufferMap)
    {
      fb.dispose();
    }
    frameBufferMap.clear();
  }
}
