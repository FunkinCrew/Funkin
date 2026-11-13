package funkin.ui;

import funkin.util.stateMachine.LogicalState;
import funkin.util.stateMachine.StateMachine;

/**
 * States of ui.
 */
enum abstract UIState(String) from String to String
{
  // GENERAL

  /**
   * Idling in a menu.
   */
  public var Idle = 'Idle';

  /**
   * Interacting in a menu.
   */
  public var Interacting = 'Interacting';

  /**
   * Exiting a menu.
   */
  public var Exiting = 'Exiting';

  /**
   * The machine is disabled.
   */
  public var Disabled = 'Disabled';

  // MAIN MENU

  /**
   * Entering the Main Menu.
   */
  public var EnteringMainMenu = 'EnteringMainMenu';

  // FREEPLAY

  /**
   * Entering the Freeplay.
   */
  public var EnteringFreeplay = 'EnteringFreeplay';

  // STORY MENU

  /**
   * Entering the Story Menu.
   */
  public var EnteringStoryMenu = 'EnteringStoryMenu';

  /**
   * Selected a level.
   */
  public var LevelSelected = 'LevelSelected';

  // CHARACTER SELECT

  /**
   * Playing the unlock animation.
   */
  public var UnlockAnimation = 'UnlockAnimation';

  /**
   * Selected a character.
   */
  public var CharacterSelected = 'CharacterSelected';

  // QUICK PANEL

  /**
   * The panel is open.
   */
  public var PanelOpen = 'PanelOpen';

  /**
   * The panel is closed.
   */
  public var PanelClosed = 'PanelClosed';

  /**
   * The panel is loading.
   */
  public var PanelLoading = 'PanelLoading';

  /**
   * The panel is getting dragged.
   */
  public var PanelDragging = 'PanelDragging';

  /**
   * The panel is confirming.
   */
  public var PanelConfirming = 'PanelConfirming';
}

/**
 * A state machine for ui.
 */
@:nullSafety
class UIStateMachine extends StateMachine
{
  /**
   * List of all the ui states.
   *
   * TODO: maybe it should use a macros...
   */
  public static final stateList:Array<String> = [
    Idle,
    Interacting,
    Exiting,
    Disabled,
    EnteringMainMenu,
    EnteringFreeplay,
    EnteringStoryMenu,
    LevelSelected,
    UnlockAnimation,
    CharacterSelected,
    PanelOpen,
    PanelClosed,
    PanelLoading,
    PanelDragging,
    PanelConfirming
  ];

  /**
   * A default map of valid transitions.
   */
  public static final defaultTransitionMap:Map<String, Array<String>> = [
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

  public function new(id:String = '',
    ?transitions:Map<String, Array<String>>,
    ?defaultStateId:String)
  {
    var validTransitions:Map<String, Array<String>> = (transitions != null) ? transitions : defaultTransitionMap;

    super(id, stateList, validTransitions, defaultStateId);
  }

  /**
   * Checks whether the UI can be interacted with based on the current state.
   * @return `true` if the UI can be interacted with, `false` otherwise.
   */
  public function canInteract():Bool
  {
    if (currentState == null)
    {
      return false;
    }

    final interactableStateIds:Array<String> = [Idle, EnteringMainMenu, CharacterSelected, PanelOpen];
    for (stateId in interactableStateIds)
    {
      if (currentState.id == stateId)
      {
        return true;
      }
    }

    return false;
  }
}
