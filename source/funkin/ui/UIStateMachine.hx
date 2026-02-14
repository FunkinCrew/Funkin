package funkin.ui;

/**
 * Simple state machine for UI components
 * Replaces scattered boolean flags with clean state management
 */
enum UIState
{
  Idle;
  Interacting;
  EnteringMainMenu;
  EnteringFreeplay;
  Exiting;
  Disabled;
}

/**
 * Note: Not to be confust with FlxState or FlxSubState!
 * State as in the design pattern!
 * https://refactoring.guru/design-patterns/state
 *
 * TODO: Generalize this a bit more to allow the UIState enum be defined with any enum
 */
@:nullSafety
class UIStateMachine
{
  public var currentState(default, null):UIState = Idle;
  public var previousState(default, null):UIState = Idle;

  var validTransitions:Map<UIState, Array<UIState>>;
  var onStateChange:Array<(UIState, UIState) -> Void> = [];

  public function new(?transitions:Map<UIState, Array<UIState>>)
  {
    // Default valid transitions if none provided
    validTransitions = transitions != null ? transitions : [Idle => [Interacting, EnteringMainMenu, EnteringFreeplay, Exiting, Disabled], EnteringMainMenu => [Idle, Exiting, Disabled, Interacting], Interacting => [Idle, EnteringMainMenu, EnteringFreeplay, Exiting, Disabled], Exiting => [Idle], Disabled => [Idle], EnteringFreeplay => [Idle]];
  }

  public function canTransition(from:UIState, to:UIState):Bool
  {
    if (from != currentState) return false;

    var allowedStates = validTransitions.get(from);
    return allowedStates != null && allowedStates.contains(to);
  }

  public function transition(newState:UIState):Bool
  {
    // Allow same-state transitions (idempotent)
    if (currentState == newState)
    {
      log('State transition ${currentState} -> ${newState} (no change)');
      return true;
    }

    if (!canTransition(currentState, newState))
    {
      log('State transition: ${currentState} -> ${newState} (INVALID, blocked)');
      return false;
    }

    previousState = currentState;
    currentState = newState;

    log('State transition ${previousState} -> ${currentState}');

    // Notify listeners
    for (callback in onStateChange)
    {
      callback(previousState, currentState);
    }

    return true;
  }

  public function onStateChanged(callback:(UIState, UIState) -> Void):Void
  {
    onStateChange.push(callback);
  }

  public function reset():Void
  {
    previousState = currentState;
    currentState = Idle;
  }

  public function is(state:UIState):Bool
  {
    return currentState == state;
  }

  public function canInteract():Bool
  {
    // Entering is an enabled state since we want to be able to interact even during the screen fade wipe thing
    return currentState == Idle || currentState == EnteringMainMenu;
  }

  static function log(message:String):Void
  {
    trace(' UI '.bold().bg_orange() + ' $message');
  }
}
