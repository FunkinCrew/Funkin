package funkin.graphics.adobeanimate;

import flxanimate.FlxAnimate;

/**
 * A sprite which provides convenience functions for rendering a texture atlas.
 */
class FlxAtlasSprite extends FlxAnimate
{
  /**
   * The animations this sprite has available.
   * Keys are animation names, values are the animation data.
   */
  var animations:Map<String, FlxAnimateAnimation>;

  public function new(?X:Float = 0, ?Y:Float = 0)
  {
    super(X, Y);
  }
}

typedef FlxAnimateAnimation =
{
  name:String;
  startFrame:Int;
  endFrame:Int;
  loop:Bool;
}
