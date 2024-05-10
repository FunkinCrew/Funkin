package funkin.mobile;

import flixel.input.touch.FlxTouch;
import flixel.input.FlxInput;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;

/**
 * A simple button class that calls a function when touched.
 */
#if !display
@:generic
#end
class FunkinButton extends FlxSprite implements IFlxInput
{
  /**
   * Used with public variable status, means not highlighted or pressed.
   */
  public static inline var NORMAL:Int = 0;

  /**
   * Used with public variable status, means highlighted (usually from touch over).
   */
  public static inline var HIGHLIGHT:Int = 1;

  /**
   * Used with public variable status, means pressed (usually from touch click).
   */
  public static inline var PRESSED:Int = 2;

  /**
   * What animation should be played for each status.
   * Default is ['normal', 'highlight', 'pressed'].
   */
  public var statusAnimations:Array<String> = ['normal', 'highlight', 'pressed'];

  /**
   * Whether you can press the button simply by releasing the touch button over it (default).
   * If false, the input has to be pressed while hovering over the button.
   */
  public var allowSwiping:Bool = true;

  /**
   * Whether the button can use multiple fingers on it.
   */
  public var multiTouch:Bool = false;

  /**
   * Maximum distance a pointer can move to still trigger event handlers.
   * If it moves beyond this limit, onOut is triggered.
   * Defaults to `Math.POSITIVE_INFINITY` (i.e. no limit).
   */
  public var maxInputMovement:Float = Math.POSITIVE_INFINITY;

  /**
   * Shows the current state of the button, either `FunkinButton.NORMAL`,
   * `FunkinButton.HIGHLIGHT` or `FunkinButton.PRESSED`.
   */
  public var status(default, set):Int;

  /**
   * The properties of this button's `onUp` callback.
   */
  public var onUp(default, null):Void->Void;

  /**
   * The properties of this button's `onDown` callback.
   */
  public var onDown(default, null):Void->Void;

  /**
   * The properties of this button's `onOver` callback.
   */
  public var onOver(default, null):Void->Void;

  /**
   * The properties of this button's `onOut` callback.
   */
  public var onOut(default, null):Void->Void;

  public var justReleased(get, never):Bool;
  public var released(get, never):Bool;
  public var pressed(get, never):Bool;
  public var justPressed(get, never):Bool;

  /** 
   * We don't need an ID here, so let's just use `Int` as the type.
   */
  var input:FlxInput<Int>;

  /**
   * The input currently pressing this button, if none, it's `null`. Needed to check for its release.
   */
  var currentInput:IFlxInput;

  var lastStatus:Int = -1;

  /**
   * Creates a new `FunkinButton` object with a gray background.
   *
   * @param X The x position of the button.
   * @param Y The y position of the button.
   */
  public function new(X:Float = 0, Y:Float = 0):Void
  {
    super(X, Y);

    loadDefaultGraphic();

    status = multiTouch ? FunkinButton.NORMAL : FunkinButton.HIGHLIGHT;

    scrollFactor.set();

    statusAnimations[FunkinButton.HIGHLIGHT] = 'normal';

    input = new FlxInput(0);
  }

  public override function graphicLoaded():Void
  {
    super.graphicLoaded();

    setupAnimation('normal', FunkinButton.NORMAL);
    setupAnimation('highlight', FunkinButton.HIGHLIGHT);
    setupAnimation('pressed', FunkinButton.PRESSED);
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
    onOver = null;
    onOut = null;
    currentInput = null;
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
      // Update the button, but only if at least either touches are enabled
      #if FLX_POINTER_INPUT
      updateButton();
      #end

      // Trigger the animation only if the button's input status changes.
      if (lastStatus != status)
      {
        updateStatusAnimation();
        lastStatus = status;
      }
    }

    input.update();
  }

  private function updateStatusAnimation():Void
  {
    animation.play(statusAnimations[status]);
  }

  /**
   * Basic button update logic - searches for overlaps with touches and
   * the touch and calls `updateStatus()`.
   */
  private function updateButton():Void
  {
    final overlapFound:Bool = checkTouchOverlap();

    if (currentInput != null && currentInput.justReleased && overlapFound) onUpHandler();

    if (status != FunkinButton.NORMAL && (!overlapFound || (currentInput != null && currentInput.justReleased))) onOutHandler();
  }

  private function checkTouchOverlap():Bool
  {
    for (camera in cameras)
    {
      for (touch in FlxG.touches.list)
      {
        if (checkInput(touch, touch, touch.justPressedPosition, camera)) return true;
      }
    }

    return false;
  }

  private function checkInput(pointer:FlxPointer, input:IFlxInput, justPressedPosition:FlxPoint, camera:FlxCamera):Bool
  {
    if (maxInputMovement != Math.POSITIVE_INFINITY
      && justPressedPosition.distanceTo(pointer.getScreenPosition(FlxPoint.weak())) > maxInputMovement
      && input == currentInput)
    {
      currentInput = null;
    }
    else if (overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera))
    {
      updateStatus(input);

      return true;
    }

    return false;
  }

  /**
   * Updates the button status by calling the respective event handler function.
   */
  private function updateStatus(input:IFlxInput):Void
  {
    if (input.justPressed)
    {
      currentInput = input;
      onDownHandler();
    }
    else if (status == FunkinButton.NORMAL)
    {
      // Allow 'swiping' to press a button (dragging it over the button while pressed)
      if (allowSwiping && input.pressed) onDownHandler();
      else
        onOverHandler();
    }
  }

  /**
   * Internal function that handles the onUp event.
   */
  private function onUpHandler():Void
  {
    status = FunkinButton.NORMAL;
    input.release();
    currentInput = null;

    if (onUp != null) onUp();
  }

  /**
   * Internal function that handles the onDown event.
   */
  private function onDownHandler():Void
  {
    status = FunkinButton.PRESSED;
    input.press();

    if (onDown != null) onDown();
  }

  /**
   * Internal function that handles the onOver event.
   */
  private function onOverHandler():Void
  {
    status = FunkinButton.HIGHLIGHT;

    if (onOver != null) onOver();
  }

  /**
   * Internal function that handles the onOut event.
   */
  private function onOutHandler():Void
  {
    status = FunkinButton.NORMAL;
    input.release();

    if (onOut != null) onOut();
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
