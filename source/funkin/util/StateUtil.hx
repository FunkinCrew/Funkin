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
   * @param state The state to check
   */
  public static function getTopSubState(state:Null<FlxState>):Null<FlxState>
  {
    var currentState:Null<FlxState> = state;
    while (currentState?.subState != null)
    {
      currentState = currentState?.subState;
    }

    return currentState;
  }

  /**
   * @return Returns all current states.
   * @param state The base state to start from.
   */
  public static function getAllStates(state:Null<FlxState>):Array<FlxState>
  {
    var allStates:Array<FlxState> = [];
    var currentState:Null<FlxState> = state;

    while (currentState != null)
    {
      allStates.push(currentState);
      currentState = currentState.subState;
    }

    return allStates;
  }
}
