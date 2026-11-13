package funkin.util.stateMachine;

import flixel.util.FlxSignal.FlxTypedSignal;

typedef StateTransitionResult =
{
  /**
   * The state the machine transitioned into.
   */
  public var state:Null<LogicalState>;

  /**
   * The state the machine transitioned from.
   */
  public var prevState:Null<LogicalState>;
}

/**
 * A logical object that handles state of an action.
 * It's not the same as the usual states which are graphical containers.
 */
@:nullSafety
class StateMachine
{
  /**
   * An id of the machine.
   */
  public var id:String;

  /**
   * The current state of this state machine.
   */
  public var currentState:Null<LogicalState>;

  /**
   * The previous state of this state machine.
   */
  public var previousState:Null<LogicalState>;

  /**
   * The state the machine uses as an initial and default state.
   */
  public var defaultState:Null<LogicalState>;

  /**
   * List of states of the machine.
   */
  public var states:Array<LogicalState> = [];

  /**
   * A signal that dispatches on each state transition.
   */
  public var onStateChange:FlxTypedSignal<StateTransitionResult->Void> = new FlxTypedSignal<StateTransitionResult->Void>();

  public function new(id:String = '',
    stateIds:Array<String>,
    ?transitions:Map<String, Array<String>>,
    ?defaultStateId:String)
  {
    this.id = id;
    this.states = buildStates(stateIds, transitions) ?? [];

    this.defaultState = getStateByID(defaultStateId);
    if (defaultState == null)
    {
      this.defaultState = states[0];
    }

    this.currentState = defaultState;
    this.previousState = defaultState;

    if (states == null || states == [])
    {
      outputMessage('No states has been passed to state machine with id $id.');
    }
  }

  /**
   * Transition the machine into new state.
   */
  public function transition(stateId:String):Bool
  {
    if (currentState?.id == stateId)
    {
      outputMessage('State transition ${currentState?.id} -> ${stateId} (no change)');
      return true;
    }

    var targetState:Null<LogicalState> = getStateByID(stateId);
    if (targetState == null)
    {
      outputMessage('State transition: ${currentState?.id} -> ${stateId} (INVALID, blocked)');
      return false;
    }

    if (currentState != null && !currentState.canTransition(targetState))
    {
      outputMessage('State with id ${currentState?.id} cant transition into state with id ${targetState?.id}.');
      return false;
    }

    previousState = currentState;
    currentState = targetState;

    outputMessage('State transition ${previousState?.id} -> ${currentState?.id}');

    final result:StateTransitionResult = {
      state: currentState,
      prevState: previousState
    }

    onStateChange.dispatch(result);
    return true;
  }

  /**
   * Builds a state list by given ids.
   * @param stateIds A list of state ids.
   * @param transitions An optional map with transitions.
   */
  public function buildStates(stateIds:Array<String>,
    ?transitions:Map<String, Array<String>>):Null<Array<LogicalState>>
  {
    var stateList:Null<Array<LogicalState>> = [];

    for (id in stateIds)
    {
      var validTransitions:Null<Array<String>> = null;
      if (transitions != null)
      {
        validTransitions = transitions.get(id);
      }

      final newState:LogicalState = new LogicalState(id, this, validTransitions);
      stateList.push(newState);
    }

    return stateList;
  }

  /**
   * Get state by an id.
   * @param stateId ID of a state to find.
   */
  public function getStateByID(?stateId:String):Null<LogicalState>
  {
    for (state in states)
    {
      if (state.id == stateId)
      {
        return state;
      }
    }
    return null;
  }

  /**
   * Whether the current state can transition into the given state.
   * @param stateId The id of a state to transition into.
   */
  public function canTransition(stateId:String):Bool
  {
    final targetState:Null<LogicalState> = getStateByID(stateId);
    if (targetState == null)
    {
      return false;
    }

    return currentState?.canTransition(targetState) ?? false;
  }

  /**
   * Whether the current state is the one passed into the parameter.
   * @param stateId Target state id.
   */
  public function is(stateId:String):Bool
  {
    if (currentState == null) return false;

    return currentState.id == stateId;
  }

  /**
   * Resets the state machine to the default state.
   */
  public function reset():Void
  {
    previousState = currentState;
    currentState = defaultState;
  }

  /**
   * A helper function for output.
   */
  function outputMessage(message:String):Void
  {
    trace(' STATE MACHINE '.bold().bg_orange() + ' ${this.id} : $message');
  }
}
