package funkin.util;

import flixel.FlxState;

/**
 * Provides utility functions for Flixel states.
 */
@:nullSafety
class StateUtil
{
  /**
   * @return Gets the topmost substate for a state.
   * @param state The state to check.
   * @param filter An optional filter to apply.
   */
  public static function getTopSubState(state:Null<FlxState>, ?filter:Null<FlxState>->Bool):Null<FlxState>
  {
    var currentState:Null<FlxState> = state;
    while (currentState != null)
    {
      var nextState:Null<FlxState> = currentState?.subState;
      if (nextState == null || (filter != null && !filter(nextState)))
      {
        break;
      }

      currentState = nextState;
    }

    return currentState;
  }

  /**
   * @return Returns all current states.
   * @param state The base state to start from.
   * @param filter An optional filter to apply.
   */
  public static function getAllStates(state:Null<FlxState>, ?filter:Null<FlxState>->Bool):Array<FlxState>
  {
    var allStates:Array<FlxState> = [];
    var currentState:Null<FlxState> = state;
    while (currentState != null)
    {
      if (filter == null || filter(currentState))
      {
        allStates.push(currentState);
      }

      currentState = currentState.subState;
    }

    return allStates;
  }
}
