package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.addons.display.FlxTiledSprite;

/**
 * A tiled chart background that supports vertical mirroring.
 * FlxTiledSprite draws a mesh, which does not apply FlxSprite.flipY.
 */
@:access(flixel.addons.display.FlxTiledSprite)
class ChartEditorGridSprite extends FlxTiledSprite
{
  override function draw():Void
  {
    if (regen) regenGraphic();

    if (FlxG.renderBlit)
    {
      if (renderSprite != null) renderSprite.flipY = flipY;
      super.draw();
      return;
    }

    if (flipY)
    {
      for (i in 0...4) vertices[i * 2 + 1] = height - vertices[i * 2 + 1];
    }
    super.draw();
    if (flipY)
    {
      for (i in 0...4) vertices[i * 2 + 1] = height - vertices[i * 2 + 1];
    }
  }
}
#end
