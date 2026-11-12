package funkin.ui.transition;

import flixel.FlxSubState;

/**
 * Represents either a substate or a substate constructor.
 */
@:nullSafety
abstract NextSubState(Any)
{
  /**
   * Convert an FlxSubState into a `NextSubState`.
   * DEPRECATED: Pass in a function that constructs the FlxSubState instead.
   * @param state The state to use.
   * @return The NextSubState wrapping the FlxSubState.
   */
  @:from @:deprecated("use `MyState.new` or `()->new MyState()` instead of `new MyState()`)")
  public static function fromSubState(state:FlxSubState):NextSubState
  {
    return cast state;
  }

  /**
   * Convert a constructor function into a `NextSubState`.
   * @param func The constructor function.
   * @return The NextSubState wrapping the FlxSubState constructor.
   */
  @:from
  public static function fromMaker(func:() -> FlxSubState):NextSubState
  {
    trace('Building NextSubState from constructor function...');
    return cast func;
  }

  /**
   * Creates a new FlxSubState.
   * Determines whether to return an existing state or construct a new one.
   * @return The FlxSubState to use.
   */
  public function createInstance():FlxSubState
  {
    if (Std.isOfType(this, FlxSubState))
    {
      trace('Building FlxSubState from NextSubState(SubState)...');
      return cast this;
    }
    else if (Std.isOfType(this, Class))
    {
      trace('Building FlxSubState from NextSubState(Class) ...');
      return Type.createInstance(this, []);
    }
    else
    {
      trace('Building FlxSubState from NextSubState(Func) ...');
      var func:Void->FlxSubState = cast this;
      return func();
    }
  }

  /**
   * Creates an function which constructs a new FlxSubState.
   * @return A constructor function.
   */
  @:nullSafety(Off)
  public function getConstructor():() -> FlxSubState
  {
    if (Std.isOfType(this, FlxSubState))
    {
      return () ->
      {
        return cast Type.createInstance(Type.getClass(this), []);
      }
    }
    else
    {
      return cast this;
    }
  }
}
