package funkin.graphics;

import animate.internal.RenderTexture;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;

/**
 * Small flixel-animate render texture override for cliprect support!!
 */
@:nullSafety
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.BitmapData)
class FunkinRenderTexture extends RenderTexture
{
  static inline final SIZE_STEP:Int = 64;
  static inline final MAX_TEXTURES:Int = 4;

  public var exactSize:Bool = false;

  var parent:Null<FlxSprite>;

  public function new(width:Int, height:Int, ?parent:FlxSprite)
  {
    super(width, height);

    this.parent = parent;
  }

  override public function init(width:Int, height:Int):Void
  {
    if (width < 1) width = 1;
    if (height < 1) height = 1;

    if (exactSize) super.init(width, height);
    else
      super.init(roundUp(width), roundUp(height));

    var frame:FlxFrame = graphic.imageFrame.frame;
    frame.type = REGULAR;
    frame.offset.set(0, 0);
    frame.sourceSize.set(width, height);
    frame.frame.set(0, 0, width, height);
    frame.cacheFrameMatrix();
    frame.updateUV();

    purgeUnusedTextures();
  }

  function purgeUnusedTextures():Void
  {
    var unused:Array<String> = [];
    for (id => bitmap in _bitmaps)
    {
      if (bitmap != _currentBitmap) unused.push(id);
    }

    if (unused.length < MAX_TEXTURES) return;

    for (id in unused)
    {
      var bitmap = _bitmaps.get(id);
      if (bitmap != null)
      {
        if (bitmap.__texture != null) bitmap.__texture.dispose();
        bitmap.dispose();
      }
      _bitmaps.remove(id);
    }
  }

  static inline function roundUp(value:Int):Int
  {
    return Math.ceil(value / SIZE_STEP) * SIZE_STEP;
  }
}
