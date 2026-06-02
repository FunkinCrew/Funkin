package funkin.graphics.effects;

import funkin.graphics.FunkinSprite;

/**
 * Data for a `FunkinEffect`'s parameters.
 */
typedef FunkinEffectParams =
{
  /**
   * If `true`, the effect will run automatically without needing to be called.
   * Else, the effect will need to be called manually.
   */
  @:optional
  var autoRun:Bool;
}

/**
 * A `FunkinEffect` is a class that can modify a sprite's various properties.
 * For example, you can make a sprite float up and down, or make it fade away.
 */
@:nullSafety
class FunkinEffect
{
  /**
   * The ID of the effect.
   */
  public var id:String = '';

  /**
   * The parent sprite that this effect will be applied to.
   */
  public var parentSprite(default, set):Null<FunkinSprite> = null;

  function set_parentSprite(value:Null<FunkinSprite>):Null<FunkinSprite>
  {
    if (parentSprite != value)
    {
      parentSprite = value;
    }

    return value;
  }

  /**
   * Whether or not the effect is currently active.
   */
  public var active:Bool = false;

  /**
   * If `true`, the parent sprite will use render texture if the effect needs it.
   */
  public var needsRenderTexture:Bool = false;

  public function new(id:String = '', ?params:FunkinEffectParams)
  {
    this.id = id;

    if (params != null && params.autoRun != null)
    {
      if (params.autoRun)
      {
        run();
      }
    }
  }

  /**
   * Runs the effect.
   */
  public function run():Void
  {
    active = true;
  }

  /**
   * Stops the effect.
   */
  public function stop():Void
  {
    active = false;
  }

  /**
   * Updates the effect.
   * @param elapsed The elapsed time since the last update.
   */
  public function update(elapsed:Float):Void
  {
  }

  /**
   * Destroys the effect.
   */
  public function destroy():Void
  {
    parentSprite = null;
  }

  public function toString():String
  {
    return '[FunkinEffect ${id}]';
  }
}
