package funkin.graphics;

import animate.internal.RenderTexture;

/**
 * Small flixel-animate render texture override to work with Funkin's needs.
 */
@:nullSafety
class FunkinRenderTexture extends RenderTexture
{
  var parent:Null<FunkinSprite>;

  public function new(width:Int, height:Int, ?parent:FunkinSprite)
  {
    super(width, height);

    this.parent = parent;
  }

  override public function init(width:Int, height:Int):Void
  {
    if (_camera == null || (_camera.width != width || _camera.height != height))
    {
      // TODO: This is shitty, but resizing doesn't seem to work properly!!!
      _camera?.destroy();
      _camera = new FunkinCamera('', 0, 0, width, height);
    }

    super.init(width, height);

    if (parent != null)
    {
      if (parent.clipRect != null)
      {
        graphic.imageFrame.frame.clip(parent.clipRect);
      }
    }
  }
}
