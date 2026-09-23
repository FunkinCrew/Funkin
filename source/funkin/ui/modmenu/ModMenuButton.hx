package funkin.ui.modmenu;

import funkin.graphics.FunkinSprite;
import funkin.util.PropertyAnimator;
import flixel.addons.display.FlxRuntimeShader;
import flixel.system.FlxAssets.FlxGraphicAsset;

class ModMenuButton extends FunkinSprite
{
  /**
   * How far the scale dips/pops (relative to the base scale) during the 'accept' animation.
   */
  static inline final ACCEPT_SCALE_PUNCH:Float = 0.04;

  var invert(default, set):Bool = false;
  var selected(default, set):Bool = false;
  var swappedGraphics:Bool = false;

  public var graphicName:String;

  /**
   * Builds the standard animations for this button, then returns the animator with those animations.
   *
   * @param baseScale The scale of the button while idle.
   * @param selectedScale The scale of the button while highlighted.
   * @return The PropertyAnimator itself.
   */
  public function createPressAnimator(baseScale:Float, selectedScale:Float):PropertyAnimator
  {
    var animator:PropertyAnimator = new PropertyAnimator(this);

    // Highlighted.
    animator.addAnimationByName('select', 24);
    setScaleKeyframes(animator, 'select', [selectedScale]);
    animator.addProperty('select', 'selected', [true]);
    animator.addProperty('select', 'invert', [false]);

    // Idle
    animator.addAnimationByName('deselect', 24);
    setScaleKeyframes(animator, 'deselect', [baseScale]);
    animator.addProperty('deselect', 'selected', [false]);
    animator.addProperty('deselect', 'invert', [false]);

    var squash:Float = baseScale - ACCEPT_SCALE_PUNCH;
    var pop:Float = baseScale + ACCEPT_SCALE_PUNCH;

    animator.addAnimationByName('accept', 24);
    setScaleKeyframes(animator, 'accept', [
      squash,
      squash,
      pop,
      pop,
      pop,
      baseScale,
      baseScale,
      baseScale,
      baseScale
    ]);
    animator.addProperty('accept', 'invert', [
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false
    ]);
    animator.addProperty('accept', 'selected', [
      false,
      false,
      true,
      true,
      true,
      false,
      false,
      false,
      false
    ]);

    return animator;
  }

  static function setScaleKeyframes(animator:PropertyAnimator, animName:String, values:Array<Float>):Void
  {
    animator.addProperty(animName, 'scale.x', values);
    animator.addProperty(animName, 'scale.y', values);
  }

  function set_invert(val:Bool):Bool
  {
    if (!val && invert)
    {
      var graphicPath:String = (selected) ? 'ui/mods/${graphicName}-highlighted' : 'ui/mods/${graphicName}';
      loadTexture(graphicPath);
    }
    else if (val && !invert) loadTexture('ui/mods/${graphicName}-inverted');

    invert = val;
    return val;
  }

  function set_selected(val:Bool):Bool
  {
    selected = val;

    if (swappedGraphics != selected && !invert)
    {
      var graphicPath:String = (selected) ? 'ui/mods/${graphicName}-highlighted' : 'ui/mods/${graphicName}';
      loadTexture(graphicPath);
      swappedGraphics = selected;
    }

    return val;
  }

  public static function queryAssets(type:funkin.assets.Assets.AssetType,
    graphicName:String):Array<funkin.assets.Paths.AssetPath>
  {
    var results:Array<funkin.assets.Paths.AssetPath> = [];

    var states = ['', '-highlighted', '-inverted'];

    switch (type)
    {
      case IMAGE:
        results.appendUnique(states.map((v) -> funkin.assets.Paths.image('ui/mods/${graphicName}${v}')));

      default:
    }
    return results;
  }
}
