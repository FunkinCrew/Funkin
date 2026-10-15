package funkin.graphics;

import animate.internal.RenderTexture;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;

/**
 * Small flixel-animate render texture override for cliprect support!!
 */
@:nullSafety
class FunkinRenderTexture extends RenderTexture
{
  var parent:Null<FlxSprite>;

  public function new(width:Int, height:Int, ?parent:FlxSprite)
  {
    super(width, height);

    this.parent = parent;
  }

  override public function init(width:Int, height:Int):Void
  {
    super.init(width, height);

    if (parent != null)
    {
      var frame:FlxFrame = graphic.imageFrame.frame;
      if (parent.clipRect != null)
      {
        frame.clip(parent.clipRect);
      }
    }
  }
}
