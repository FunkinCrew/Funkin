package funkin.ui;

/**
 * Simple state machine for UI components
 * Replaces scattered boolean flags with clean state management
 */
enum UIState
{
  // Main Menu / Freeplay
  Idle;
  Interacting;
  EnteringMainMenu;
  EnteringFreeplay;
  Exiting;
  Disabled;
  // Character Select
  UnlockAnimation;
  CharacterSelected;
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
  /**
   * The current state of this state machine.
   */
  public var currentState(default, null):UIState = Idle;

  /**
   * The previous state of this state machine.
   */
  public var previousState(default, null):UIState = Idle;

  var validTransitions:Map<UIState, Array<UIState>>;
  var onStateChange:Array<(UIState, UIState) -> Void> = [];

  public function new(?transitions:Map<UIState, Array<UIState>>)
  {
    // Default valid transitions if none provided
    validTransitions = transitions != null ? transitions : [
      Idle => [
        Interacting,
        EnteringMainMenu,
        EnteringFreeplay,
        Exiting,
        Disabled,
        CharacterSelected,
        UnlockAnimation
      ],
      EnteringMainMenu => [Idle, Exiting, Disabled, Interacting],
      Interacting => [
        Idle,
        EnteringMainMenu,
        EnteringFreeplay,
        Exiting,
        Disabled
      ],
      Exiting => [Idle],
      Disabled => [Idle, UnlockAnimation],
      EnteringFreeplay => [Idle],
      CharacterSelected => [Idle, Exiting],
      UnlockAnimation => [Idle]
    ];
  }

  /**
   * Checks if the current state can transition to the given state.
   * @param from The state to transition from.
   * @param to The state to transition to.
   * @return `true` if it's possible, `false` otherwise.
   */
  public function canTransition(from:UIState, to:UIState):Bool
  {
    if (from != currentState) return false;

    var allowedStates = validTransitions.get(from);
    return allowedStates != null && allowedStates.contains(to);
  }

  /**
   * Transitions to the given state.
   * @param newState The state to transition to.
   * @return `true` if the transition was successful, `false` otherwise.
   */
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

  /**
   * A callback that is called whenever the state changes.
   * @param callback A custom function to call when the state changes.
   */
  public function onStateChanged(callback:(UIState, UIState) -> Void):Void
  {
    onStateChange.push(callback);
  }

  /**
   * Resets the state machine to the Idle state.
   */
  public function reset():Void
  {
    previousState = currentState;
    currentState = Idle;
  }

  /**
   * Checks whether the current state is the given state.
   * @param state The state to check.
   * @return `true` if the current state is the given state, `false` otherwise.
   */
  public function is(state:UIState):Bool
  {
    return currentState == state;
  }

  /**
   * Checks whether the UI can be interacted with based on the current state.
   * @return `true` if the UI can be interacted with, `false` otherwise.
   */
  public function canInteract():Bool
  {
    // Entering is an enabled state since we want to be able to interact even during the screen fade wipe thing
    return currentState == Idle || currentState == EnteringMainMenu || currentState == CharacterSelected;
  }

  static function log(message:String):Void
  {
    trace(' UI '.bold().bg_orange() + ' $message');
  }
}
