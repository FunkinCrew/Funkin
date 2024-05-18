package funkin.mobile;

import funkin.mobile.FunkinButton;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;

/**
 * Enum for different direction modes.
 */
enum FunkinDirectionalMode
{
  UP_DOWN;
  LEFT_RIGHT;
  UP_LEFT_RIGHT;
  LEFT_FULL;
  RIGHT_FULL;
  NONE;
}

/**
 * Enum for different action modes.
 */
enum FunkinActionMode
{
  A;
  B;
  A_B;
  A_C;
  A_B_C;
  A_B_X_Y;
  A_B_C_X_Y;
  A_B_C_X_Y_Z;
  NONE;
}

/**
 * A virtual gamepad.
 * It's easy to customize the layout.
 */
class FunkinVirtualPad extends FlxTypedSpriteGroup<FunkinButton>
{
  /**
   * The left directional button.
   */
  public var buttonLeft:FunkinButton = new FunkinButton(0, 0);

  /**
   * The up directional button.
   */
  public var buttonUp:FunkinButton = new FunkinButton(0, 0);

  /**
   * The right directional button.
   */
  public var buttonRight:FunkinButton = new FunkinButton(0, 0);

  /**
   * The down directional button.
   */
  public var buttonDown:FunkinButton = new FunkinButton(0, 0);

  /**
   * The A action button.
   */
  public var buttonA:FunkinButton = new FunkinButton(0, 0);

  /**
   * The B action button.
   */
  public var buttonB:FunkinButton = new FunkinButton(0, 0);

  /**
   * The C action button.
   */
  public var buttonC:FunkinButton = new FunkinButton(0, 0);

  /**
   * The X action button.
   */
  public var buttonX:FunkinButton = new FunkinButton(0, 0);

  /**
   * The Y action button.
   */
  public var buttonY:FunkinButton = new FunkinButton(0, 0);

  /**
   * The Z action button.
   */
  public var buttonZ:FunkinButton = new FunkinButton(0, 0);

  /**
   * Create a virtual gamepad.
   *
   * @param direction The directional mode.
   * @param action The action buttons mode.
   */
  public function new(direction:FunkinDirectionalMode = LEFT_FULL, action:FunkinActionMode = A_B_C):Void
  {
    super();

    switch (direction)
    {
      case UP_DOWN:
        add(buttonUp = createButton(0, FlxG.height - 255, 'up', 0xFF12FA05, DIRECTION_BUTTON));
        add(buttonDown = createButton(0, FlxG.height - 135, 'down', 0xFF00FFFF, DIRECTION_BUTTON));
      case LEFT_RIGHT:
        add(buttonLeft = createButton(0, FlxG.height - 135, 'left', 0xFFC24B99, DIRECTION_BUTTON));
        add(buttonRight = createButton(127, FlxG.height - 135, 'right', 0xFFF9393F, DIRECTION_BUTTON));
      case UP_LEFT_RIGHT:
        add(buttonUp = createButton(105, FlxG.height - 243, 'up', 0xFF12FA05, DIRECTION_BUTTON));
        add(buttonLeft = createButton(0, FlxG.height - 135, 'left', 0xFFC24B99, DIRECTION_BUTTON));
        add(buttonRight = createButton(207, FlxG.height - 135, 'right', 0xFFF9393F, DIRECTION_BUTTON));
      case LEFT_FULL:
        add(buttonUp = createButton(105, FlxG.height - 345, 'up', 0xFF12FA05, DIRECTION_BUTTON));
        add(buttonLeft = createButton(0, FlxG.height - 243, 'left', 0xFFC24B99, DIRECTION_BUTTON));
        add(buttonRight = createButton(207, FlxG.height - 243, 'right', 0xFFF9393F, DIRECTION_BUTTON));
        add(buttonDown = createButton(105, FlxG.height - 135, 'down', 0xFF00FFFF, DIRECTION_BUTTON));
      case RIGHT_FULL:
        add(buttonUp = createButton(FlxG.width - 258, FlxG.height - 408, 'up', 0xFF12FA05, DIRECTION_BUTTON));
        add(buttonLeft = createButton(FlxG.width - 384, FlxG.height - 309, 'left', 0xFFC24B99, DIRECTION_BUTTON));
        add(buttonRight = createButton(FlxG.width - 132, FlxG.height - 309, 'right', 0xFFF9393F, DIRECTION_BUTTON));
        add(buttonDown = createButton(FlxG.width - 258, FlxG.height - 201, 'down', 0xFF00FFFF, DIRECTION_BUTTON));
      case NONE: // do nothing
    }

    switch (action)
    {
      case A:
        add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, ACTION_BUTTON));
      case B:
        add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, 'b', 0xFFCB00, ACTION_BUTTON));
      case A_B:
        add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, 'b', 0xFFCB00, ACTION_BUTTON));
        add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, ACTION_BUTTON));
      case A_C:
        add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, 'c', 0x44FF00, ACTION_BUTTON));
        add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, ACTION_BUTTON));
      case A_B_C:
        add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, 'c', 0x44FF00, ACTION_BUTTON));
        add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, 'b', 0xFFCB00, ACTION_BUTTON));
        add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, ACTION_BUTTON));
      case A_B_X_Y:
        add(buttonX = createButton(FlxG.width - 510, FlxG.height - 135, 'x', 0x99062D, ACTION_BUTTON));
        add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, 'b', 0xFFCB00, ACTION_BUTTON));
        add(buttonY = createButton(FlxG.width - 384, FlxG.height - 135, 'y', 0x4A35B9, ACTION_BUTTON));
        add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, ACTION_BUTTON));
      case A_B_C_X_Y:
        add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, 'c', 0x44FF00, ACTION_BUTTON));
        add(buttonX = createButton(FlxG.width - 258, FlxG.height - 255, 'x', 0x99062D, ACTION_BUTTON));
        add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, 'b', 0xFFCB00, ACTION_BUTTON));
        add(buttonY = createButton(FlxG.width - 132, FlxG.height - 255, 'y', 0x4A35B9, ACTION_BUTTON));
        add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, ACTION_BUTTON));
      case A_B_C_X_Y_Z:
        add(buttonX = createButton(FlxG.width - 384, FlxG.height - 255, 'x', 0x99062D, ACTION_BUTTON));
        add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, 'c', 0x44FF00, ACTION_BUTTON));
        add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, 'y', 0x4A35B9, ACTION_BUTTON));
        add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, 'b', 0xFFCB00, ACTION_BUTTON));
        add(buttonZ = createButton(FlxG.width - 132, FlxG.height - 255, 'z', 0xCCB98E, ACTION_BUTTON));
        add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, ACTION_BUTTON));
      case NONE: // do nothing
    }

    scrollFactor.set();

    zIndex = 100000;
  }

  private function createButton(x:Float, y:Float, key:String, color:Int = 0xFFFFFF, role:FunkinButtonRole):FunkinButton
  {
    var graphic:FlxGraphic = FlxG.bitmap.add('assets/vpad/$key.png');

    var button:FunkinButton = new FunkinButton(x, y, role);
    button.loadGraphic(graphic, true, Std.int(graphic.width / 2), graphic.height);
    button.animation.add('normal', [0], 0, false);
    button.animation.add('pressed', [1], 0, false);
    button.animation.play('normal');
    button.color = color;
    button.alpha = 0.4;
    button.onDown.add(button.animation.play.bind('pressed'));
    button.onUp.add(button.animation.play.bind('normal'));
    button.onOut.add(button.animation.play.bind('normal'));
    return button;
  }

  /**
   * Clean up memory.
   */
  override public function destroy():Void
  {
    for (field in Reflect.fields(this))
    {
      if (field != null)
      {
        var button:Dynamic = Reflect.field(this, field);

        if (button is FunkinButton) Reflect.setField(this, field, FlxDestroyUtil.destroy(button));
      }
    }

    super.destroy();
  }
}
