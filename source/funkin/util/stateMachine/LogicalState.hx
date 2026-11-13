package funkin.util.stateMachine;

/**
 * Class defining a state of action.
 * It's not the same as the usual states which are graphical containers.
 */
@:nullSafety
class LogicalState
{
  /**
   * An id of the state.
   */
  public var id:String;

  /**
   * The parent state machine of the state.
   * Used to ensure that both states on transition are from the same machine.
   */
  public var parent:StateMachine;

  /**
   * A list of transitions the state is allowed to transition into.
   * Any state is allowed if null.
   */
  public var validTransitions:Null<Array<String>>;

  public function new(id:String, parent:StateMachine, ?validTransitions:Array<String>)
  {
    this.id = id;
    this.parent = parent;
    this.validTransitions = validTransitions;
  }

  /**
   * Whether the state can transition into the given state.
   * @param state The state to transition into.
   */
  public function canTransition(state:LogicalState):Bool
  {
    if (state == null || state.parent != parent) return false;

    if (validTransitions != null && validTransitions != [])
    {
      if (validTransitions.contains(state.id))
      {
        return true;
      }

      return false;
    }

    return true;
  }
}
