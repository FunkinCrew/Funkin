package funkin.play;

import funkin.util.stateMachine.StateMachine;
import funkin.ui.MusicBeatSubState;
import funkin.play.pause.PauseSubState;
import funkin.play.song.Song.SongState;
import funkin.play.PlayState;

/**
 * Defines the current state of the gameplay cycle.
 */
enum abstract GameplayState(String) from String to String
{
  /**
   * The game is currently in a cutscene.
   */
  public var Cutscene = 'Cutscene';

  /**
   * The countdown is being performed.
   */
  public var InCountdown = 'InCountdown';

  /**
   * The song plays.
   */
  public var Song = 'Song';

  /**
   * The player is dead.
   */
  public var GameOver = 'GameOver';
}

/**
 * A state machine for defining current state of `PlayState`.
 */
@:nullSafety
class GameplayStateMachine extends StateMachine
{
  /**
   * List of all the gameplay states.
   *
   * TODO: maybe it should use a macros...
   */
  public static final stateList:Array<String> = [Cutscene, InCountdown, Song, GameOver];

  /**
   * A default map of valid transitions.
   */
  public static final defaultTransitionMap:Map<String, Array<String>> = [Cutscene => [InCountdown, Song]];

  /**
   * The PlayState the state machine is used for.
   */
  public var parent:Null<PlayState>;

  /**
   * State of the current song.
   */
  public var songState:StateMachine;

  /**
   * If one of the specific substates is rendering over the parent, it is paused and normal update logic is skipped.
   */
  public var isGamePaused(get, never):Bool;

  function get_isGamePaused():Bool
  {
    if (parent == null || parent.subState == null) return false;

    final pausingClasses:Array<Class<MusicBeatSubState>> = [PauseSubState, GameOverSubState];

    for (classType in pausingClasses)
    {
      if (Std.isOfType(parent.subState, classType))
      {
        return true;
      }
    }

    return false;
  }

  public function new(id:String = '', songState:StateMachine)
  {
    super(id, stateList, defaultTransitionMap, InCountdown);

    this.songState = songState;
  }

  /**
   * Sets parent `PlayState`.
   */
  public function setParent(parent:PlayState):Void
  {
    this.parent = parent;
  }

  /**
   * Whether the player can pause the game.
   */
  public var mayPauseGame(get, never):Bool;

  public function get_mayPauseGame():Bool
  {
    return !this.is(GameOver) && !songState.is(SongState.Ending);
  }

  /**
   * Helper function for transitioning to the `Cutscene` state.
   */
  public function enterCutscene():Bool
  {
    return transition(Cutscene);
  }

  /**
   * Helper function for defining if the machine is in the `Cutscene` state.
   */
  public function isCutscene():Bool
  {
    return is(Cutscene);
  }

  /**
   * Helper function for transitioning to the `InCountdown` state.
   */
  public function enterCountdown():Bool
  {
    songState.transition(Starting);

    return transition(InCountdown);
  }

  /**
   * Helper function for defining if the machine is in the `InCountdown` state.
   */
  public function isCountdown():Bool
  {
    return is(InCountdown);
  }

  /**
   * Helper function for transitioning to the `Song` state.
   */
  public function enterSong():Bool
  {
    return transition(Song);
  }

  /**
   * Helper function for defining if the machine is in the `Song` state.
   */
  public function isSong():Bool
  {
    return is(Song);
  }

  /**
   * Helper function for transitioning to the `GameOver` state.
   */
  public function enterGameOver():Bool
  {
    return transition(GameOver);
  }

  /**
   * Helper function for defining if the machine is in the `GameOver` state.
   */
  public function isGameOver():Bool
  {
    return is(GameOver);
  }
}
