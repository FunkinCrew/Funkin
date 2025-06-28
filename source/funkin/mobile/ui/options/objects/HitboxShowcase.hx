package funkin.mobile.ui.options.objects;

import flixel.addons.display.shapes.FlxShapeBox;
import flixel.group.FlxSpriteGroup;
import flixel.effects.FlxFlicker;
import flixel.util.FlxSignal;
import flixel.util.FlxColor;
import flixel.FlxG;
import funkin.mobile.ui.FunkinHitbox;
import funkin.audio.FunkinSound;
import funkin.util.MathUtil;

/**
 * Represents a showcase hitbox in the scheme menu.
 */
class HitboxShowcase extends FlxSpriteGroup
{
  /**
   * An array of values for lerping object's alpha.
   */
  static final HITBOX_SHOWCASE_ALPHA:Array<Float> = [0.3, 1];

  /**
   * Object's own index.
   */
  public var index:Int;

  /**
   * Current selection's index from menu where this object is used.
   */
  public var selectionIndex:Int;

  /**
   * Indicates if object's index is equal to current selection's index.
   */
  public var selected(get, never):Bool;

  /**
   * Signal dispatched when the object is selected. Additional behavior can be added by subscribing to this signal.
   */
  public var onSelect(default, null):FlxSignal = new FlxSignal();

  /**
   * Indicates if the object is currently processing a selection (to avoid multiple triggers).
   */
  public var busy:Bool = false;

  /**
   * Creates a new HitboxShowcase instance.
   *
   * @param x The x position of the object.
   * @param y The y position of the object.
   * @param index An integer used as object's index.
   * @param selectionIndex Menu's current selection index.
   * @param controlsScheme Hitbox's controls scheme.
   * @param onClick An optional callback function that will be triggered when the object is clicked.
   */
  public function new(x:Int = 0, y:Int = 0, index:Int, selectionIndex:Int = 0, controlsScheme:String, ?onClick:Void->Void):Void
  {
    super(x, y);

    this.index = index;
    this.selectionIndex = selectionIndex;

    setupObjects(controlsScheme);

    alpha = HITBOX_SHOWCASE_ALPHA[selected ? 1 : 0];

    if (onClick != null) onSelect.add(onClick);
  }

  /**
   * Creates and setups every needed object.
   *
   * @param controlsScheme Hitbox's controls scheme.
   */
  function setupObjects(controlsScheme:String):Void
  {
    final bg:FlxShapeBox = new FlxShapeBox(0, 0, FlxG.width + 2, FlxG.height + 2, {thickness: 6, color: FlxColor.BLACK}, FlxColor.GRAY);
    bg.screenCenter();
    add(bg);

    final hitbox:FunkinHitbox = new FunkinHitbox(controlsScheme, false);
    hitbox.forEachAlive(function(hint:FunkinHint):Void {
      if (controlsScheme != FunkinHitbox.FunkinHitboxControlSchemes.FourLanes) hint.alpha = 0.3;
    });
    hitbox.active = false;
    add(hitbox);
  }

  /**
   * Called when the object is both selected and pressed.
   */
  public function onPress():Void
  {
    if (!busy)
    {
      busy = true;

      FunkinSound.playOnce(Paths.sound('confirmMenu'));

      FlxFlicker.flicker(this, 1, 0.06, true, false, function(_) {
        busy = false;
        onSelect.dispatch();
      });
    }
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    alpha = MathUtil.smoothLerpPrecision(alpha, HITBOX_SHOWCASE_ALPHA[selected ? 1 : 0], elapsed, 0.2);
  }

  function get_selected():Bool
  {
    return index == selectionIndex;
  }
}
