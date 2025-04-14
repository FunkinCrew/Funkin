package funkin.mobile.ui.options.objects;

import flixel.group.FlxSpriteGroup;
import flixel.addons.display.shapes.FlxShapeBox;
import flixel.util.FlxColor;
import flixel.FlxG;
import funkin.mobile.ui.FunkinHitbox;
import funkin.graphics.FunkinCamera;
import funkin.util.MathUtil;

/**
 * Represents a showcase hitbox in the scheme menu.
 */
@:nullSafety
class HitboxShowcase extends FlxSpriteGroup
{
  /**
   * The group's main camera.
   */
  public var camHitbox:Null<FunkinCamera>;

  /**
   * An array of values for lerping object's alpha.
   */
  private static final HITBOX_SHOWCASE_ALPHA:Array<Float> = [0.3, 1];

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
   * Creates a new HitboxShowcase instance.
   *
   * @param x The x position of the object.
   * @param y The y position of the object.
   * @param index An integer used as object's index.
   * @param selectionIndex Menu's current selection index.
   * @param controlsScheme Hitbox's controls scheme.
   */
  public function new(x:Int = 0, y:Int = 0, index:Int, selectionIndex:Int = 0, controlsScheme:String)
  {
    super(x, y);

    this.index = index;
    this.selectionIndex = selectionIndex;

    setupObjects(controlsScheme);
  }

  /**
   * Creates and setups every needed object.
   *
   * @param controlsScheme Hitbox's controls scheme.
   */
  function setupObjects(controlsScheme:String)
  {
    camHitbox = new FunkinCamera('camHitbox' + index);
    camHitbox.bgColor = 0x0;
    camHitbox.setScale(0.5, 0.5);
    FlxG.cameras.add(camHitbox);

    final bg:FlxShapeBox = new FlxShapeBox(0, 0, FlxG.width + 2, FlxG.height + 2, {thickness: 6, color: FlxColor.BLACK}, FlxColor.GRAY);
    bg.screenCenter();
    add(bg);

    final hitbox:FunkinHitbox = new FunkinHitbox(controlsScheme);
    hitbox.screenCenter();
    hitbox.forEachAlive(function(hint:FunkinHint):Void {
      hint.alpha = 0.3;
      @:privateAccess
      if (hint.label != null) hint.label.alpha = 0.3;
    });
    hitbox.active = false;
    add(hitbox);

    this.cameras = [camHitbox];
  }

  public override function update(elapsed:Float)
  {
    super.update(elapsed);

    alpha = MathUtil.smoothLerp(alpha, HITBOX_SHOWCASE_ALPHA[selected ? 1 : 0], elapsed, 0.5);
  }

  function get_selected()
  {
    return index == selectionIndex;
  }
}
