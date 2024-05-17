package funkin.mobile;

import funkin.graphics.FunkinSprite;
import funkin.util.TouchUtil;
import flixel.input.FlxInput;
import flixel.input.IFlxInput;

/**
 * A simple button class that calls a function when touched.
 */
#if !display
@:generic
#end
class FunkinButton extends FunkinSprite implements IFlxInput
{
  /**
   * Used with public variable status, means not pressed.
   */
  public static inline var NORMAL:Int = 0;

  /**
   * Used with public variable status, means pressed (usually from touch click).
   */
  public static inline var PRESSED:Int = 2;

  /**
   * What animation should be played for each status.
   * Default is ['normal', 'pressed'].
   */
  public var statusAnimations:Array<String> = ['normal', 'pressed'];

  /**
   * Shows the current state of the button, either `FunkinButton.NORMAL` or `FunkinButton.PRESSED`.
   */
  public var status:Int;

  /**
   * The properties of this button's `onUp` callback.
   */
  public var onUp:Void->Void;

  /**
   * The properties of this button's `onDown` callback.
   */
  public var onDown:Void->Void;

  public var justReleased(get, never):Bool;
  public var released(get, never):Bool;
  public var pressed(get, never):Bool;
  public var justPressed(get, never):Bool;

  public var role:ButtonRole;
  public var tag:String;

  /**
   * We don't need an ID here, so let's just use `Int` as the type.
   */
  var input:FlxInput<Int>;

  var lastStatus:Int = -1;

  /**
   * Creates a new `FunkinButton` object with a gray background.
   *
   * @param X The x position of the button.
   * @param Y The y position of the button.
   */
  public function new(X:Float = 0, Y:Float = 0, ?role:ButtonRole):Void
  {
    super(X, Y);

    loadDefaultGraphic();

    status = FunkinButton.NORMAL;

    scrollFactor.set();

    input = new FlxInput(0);

    this.role = role;
  }

  public override function graphicLoaded():Void
  {
    super.graphicLoaded();

    setupAnimation('normal', FunkinButton.NORMAL);
    setupAnimation('pressed', FunkinButton.PRESSED - 1);
  }

  private function loadDefaultGraphic():Void
  {
    loadGraphic('flixel/images/ui/button.png', true, 80, 20);
  }

  private function setupAnimation(animationName:String, frameIndex:Int):Void
  {
    // make sure the animation doesn't contain an invalid frame
    frameIndex = Std.int(Math.min(frameIndex, #if (flixel < "5.3.0") animation.frames #else animation.numFrames #end - 1));
    animation.add(animationName, [frameIndex]);
  }

  /**
   * Called by the game state when state is changed (if this object belongs to the state)
   */
  public override function destroy():Void
  {
    onUp = null;
    onDown = null;
    input = null;

    super.destroy();
  }

  /**
   * Called by the game loop automatically, handles touch over and click detection.
   */
  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (visible)
    {
      // Update input.
      final touchOverlaps:Bool = TouchUtil.overlapsComplex(this);

      if (touchOverlaps)
      {
        if (TouchUtil.justPressed || (status == FunkinButton.NORMAL && TouchUtil.pressed))
        {
          status = FunkinButton.PRESSED;

          input.press();

          if (onDown != null) onDown();
        }

        if (TouchUtil.justReleased)
        {
          status = FunkinButton.NORMAL;

          input.release();

          if (onUp != null) onUp();
        }
      }
      else if (status != FunkinButton.NORMAL && TouchUtil.justReleased)
      {
          status = FunkinButton.NORMAL;

          input.release();

          if (onUp != null) onUp();
      }

      // Trigger the animation only if the button's input status changes.
      if (lastStatus != status)
      {
        switch (status)
        {
            case FunkinButton.PRESSED:
              animation.play('pressed');
            case FunkinButton.NORMAL:
              animation.play('normal');
        }

        lastStatus = status;
      }
    }

    input.update();
  }

  private inline function get_justReleased():Bool
  {
    return input.justReleased;
  }

  private inline function get_released():Bool
  {
    return input.released;
  }

  private inline function get_pressed():Bool
  {
    return input.pressed;
  }

  private inline function get_justPressed():Bool
  {
    return input.justPressed;
  }
}

enum ButtonRole
{
  DIRECTION_BUTTON;
  ACTION_BUTTON;
}
