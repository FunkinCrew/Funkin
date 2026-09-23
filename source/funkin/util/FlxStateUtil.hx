package funkin.util;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.Transition;
import funkin.ui.transition.loading.LoadingState;

/**
 * Utility class for working with FlxState.
 */
@:nullSafety
class FlxStateUtil
{
  /**
   * Determine if the given FlxState is an FlxSubState.
   * @param state The state to evaluate.
   * @return Whether the state is a substate.
   */
  public static function isSubState(state:FlxState):Bool
  {
    return Std.isOfType(state, FlxSubState);
  }

  /**
   * Determine if the given FlxState is a Transition.
   * @param state The state to evaluate.
   * @return Whether the state is a transition.
   */
  public static function isTransition(state:FlxState):Bool
  {
    return Std.isOfType(state, Transition);
  }

  /**
   * Determine if the given FlxState is a LoadingState.
   * @param state The state to evaluate.
   * @return Whether the state is a transition.
   */
  public static function isLoadingState(state:FlxState):Bool
  {
    return Std.isOfType(state, LoadingState);
  }

  /**
   * Determine whether the target state has a valid substate.
   * @param state The state to query.
   * @param ignoreTransitions If `true`, only return true if the substate is not a transition.
   * @return Whether the state has a substate.
   */
  public static function hasSubState(state:FlxState, ?ignoreTransitions:Bool = true):Bool
  {
    @:privateAccess
    {
      var hasSubState:Bool = (state._requestedSubState != null) || (state.subState != null && !state._requestSubStateReset);
      if (!hasSubState) return false;

      var subState:FlxSubState = state._requestedSubState ?? state.subState;

      if (ignoreTransitions && isTransition(subState)) return false;

      return true;
    }
  }

  /**
   * Get the topmost state or substate of a given state.
   * @param state The state to get the topmost state or substate of.
   * @param ignoreTransitions Whether to ignore Transition substates.
   * @return The topmost state or substate of the given state.
   */
  public static function getTopmostState(state:FlxState, ?ignoreTransitions:Bool = true):FlxState
  {
    while (hasSubState(state, ignoreTransitions))
    {
      @:privateAccess
      state = state._requestedSubState ?? state.subState;
    }
    return state;
  }

  /**
   * Get the topmost substate of a given state.
   * @param state The state to get the topmost substate of.
   * @param ignoreTransitions Whether to ignore Transition substates.
   * @return The topmost substate of the given state, or null if the given state has no substate.
   */
  public static function getTopmostSubState(state:FlxState, ?ignoreTransitions:Bool = true):Null<FlxSubState>
  {
    if (!hasSubState(state, ignoreTransitions))
    {
      return null;
    }

    @:privateAccess
    {
      var subState:FlxSubState = state._requestedSubState ?? state.subState;
      while (hasSubState(subState, ignoreTransitions))
      {
        subState = subState._requestedSubState ?? subState.subState;
      }
      return subState;
    }
  }

  /**
   * Open a substate on top of the topmost state or substate.
   * @param subState The substate to switch to.
   * @param targetState The target state to open the substate on. Defaults to the current state.
   */
  public static function openSubStateAtTop(subState:FlxSubState, ?targetState:FlxState):Void
  {
    if (targetState == null)
    {
      targetState = FlxG.state;
    }

    var topmostState:FlxState = getTopmostState(targetState, true);

    @:privateAccess
    var currentSubState:Null<FlxSubState> = topmostState?._requestedSubState ?? topmostState?.subState;
    if (currentSubState != null && currentSubState == subState)
    {
      // No need to do anything.
      return;
    }

    // Then, open the substate on top of that.
    topmostState.openSubState(subState);
  }

  /**
   * Close the topmost substate of a given state.
   * @param state The state to get the topmost substate of and close.
   * @param ignoreTransitions Whether to ignore Transition substates.
   */
  public static function closeSubStateAtTop(state:FlxState, ?ignoreTransitions:Bool = true):Void
  {
    var topmostSubState:Null<FlxSubState> = getTopmostSubState(state, ignoreTransitions);

    if (topmostSubState == null)
    {
      if (isSubState(state))
      {
        // If the targeted state IS itself a substate, close that.
        var subState:FlxSubState = cast state;
        subState.close();
      }
      else
      {
        // No sub-state to close.
      }
    }
    else
    {
      topmostSubState.close();
    }
  }

  public static function cancelTransitionAtTop(state:FlxState):Bool
  {
    var topmostSubState:Null<FlxSubState> = getTopmostSubState(state, false);

    if (topmostSubState == null)
    {
      if (isTransition(state))
      {
        var transition:Transition = cast state;
        @:privateAccess @:nullSafety(Off) transition.finishCallback = null;
        transition.close();
        return true;
      }
      return false;
    }

    if (isTransition(topmostSubState))
    {
      @:nullSafety(Off)
      var transition:Transition = cast topmostSubState;
      @:privateAccess @:nullSafety(Off) transition.finishCallback = null;
      transition.close();
      return true;
    }

    if (Std.isOfType(topmostSubState, funkin.ui.transition.loading.LoadingState))
    {
      var loadingState:funkin.ui.transition.loading.LoadingState = cast topmostSubState;
      loadingState.cancelTransition();
      return true;
    }

    return false;
  }

  /**
   * Close the topmost substate of a given state, if it is a Transition.
   * @param state The state to get the topmost substate of and close.
   */
  public static function closeTransitionAtTop(state:FlxState):Void
  {
    var topmostSubState:Null<FlxSubState> = getTopmostSubState(state, false);

    if (topmostSubState == null)
    {
      if (isTransition(state))
      {
        var transition:Transition = cast state;
        transition.close();
      }
      else
      {
        trace('No transition found to close...');
      }
    }
    else
    {
      if (isTransition(topmostSubState))
      {
        var transition:Transition = cast topmostSubState;
        transition.close();
      }
      else
      {
        trace('No transition found to close...');
      }
    }
  }
}
