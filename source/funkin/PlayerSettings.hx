package funkin;

import funkin.save.Save;
import funkin.input.Controls;
import funkin.input.PreciseInputManager;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * A core class which represents the current player(s) and their controls and other configuration.
 */
@:nullSafety
class PlayerSettings
{
  // TODO: Finish implementation of second player.
  public static var numPlayers(default, null) = 0;
  public static var numAvatars(default, null) = 0;
  // TODO: Making both of these null makes a lot of errors with the controls.
  // That'd explain why unplugging input devices can cause the game to crash?
  @:nullSafety(Off)
  public static var player1(default, null):PlayerSettings;
  @:nullSafety(Off)
  public static var player2(default, null):PlayerSettings;

  public static var onAvatarAdd(default, null) = new FlxTypedSignal<PlayerSettings->Void>();
  public static var onAvatarRemove(default, null) = new FlxTypedSignal<PlayerSettings->Void>();

  /**
   * The player number associated with this settings object.
   */
  public var id(default, null):Int;

  /**
   * The controls handler for this player.
   */
  public var controls(default, null):Controls;

  /**
   * Return the PlayerSettings for the given player number, or `null` if that player isn't active.
   *
   * @param id The player number this represents.
   * @return The PlayerSettings for the given player number, or `null` if that player isn't active.
   */
  public static function get(id:Int):Null<PlayerSettings>
  {
    return switch (id)
    {
      case 1: player1;
      case 2: player2;
      default: null;
    };
  }

  /**
   * Initialize the PlayerSettings singletons for each player.
   */
  public static function init():Void
  {
    if (player1 == null)
    {
      player1 = new PlayerSettings(1);
      ++numPlayers;
    }

    FlxG.gamepads.deviceConnected.add(onGamepadAdded);

    var numGamepads = FlxG.gamepads.numActiveGamepads;
    for (i in 0...numGamepads)
    {
      var gamepad = FlxG.gamepads.getByID(i);
      if (gamepad != null) onGamepadAdded(gamepad);
    }
  }

  /**
   * Forcibly destroy the PlayerSettings singletons for each player.
   */
  @:nullSafety(Off)
  public static function reset():Void
  {
    player1 = null;
    player2 = null;
    numPlayers = 0;
  }

  /**
   * Callback invoked when a gamepad is added.
   * @param gamepad The gamepad that was added.
   */
  static function onGamepadAdded(gamepad:FlxGamepad):Void
  {
    // TODO: Make this detect and handle multiple players
    player1.addGamepad(gamepad);
  }

  /**
   * @param id The player number this represents. This was refactored to START AT `1`.
   */
  function new(id:Int)
  {
    trace('loading player settings for id: $id');

    this.id = id;
    this.controls = new Controls('player$id', None);

    addKeyboard();
  }

  function addKeyboard():Void
  {
    var useDefault:Bool = true;
    if (Save.instance.hasControls(id, Keys))
    {
      var keyControlData = Save.instance.getControls(id, Keys);
      trace('Loading keyboard control scheme from user save');
      useDefault = false;
      controls.fromSaveData(keyControlData, Keys);
    }
    else
    {
      useDefault = true;
    }

    if (useDefault)
    {
      trace('Loading default keyboard control scheme');
      controls.setKeyboardScheme(Solo);
    }

    PreciseInputManager.instance.initializeKeys(controls);
  }

  /**
   * Called after an FlxGamepad has been detected.
   * @param gamepad The gamepad that was detected.
   */
  function addGamepad(gamepad:FlxGamepad):Void
  {
    var useDefault = true;
    if (Save.instance.hasControls(id, Gamepad(gamepad.id)))
    {
      var padControlData = Save.instance.getControls(id, Gamepad(gamepad.id));
      trace('Loading gamepad control scheme from user save');
      useDefault = false;
      controls.addGamepadWithSaveData(gamepad.id, padControlData);
    }
    else
    {
      useDefault = true;
    }

    if (useDefault)
    {
      trace('Loading default gamepad control scheme');
      controls.addDefaultGamepad(gamepad.id);
    }
    PreciseInputManager.instance.initializeButtons(controls, gamepad);
  }

  /**
   * Save this player's controls to the game's persistent save.
   */
  public function saveControls():Void
  {
    var keyData = controls.createSaveData(Keys);
    if (keyData != null)
    {
      trace('Saving keyboard control scheme to user save');
      Save.instance.setControls(id, Keys, keyData);
    }

    if (controls.gamepadsAdded.length > 0)
    {
      var padData = controls.createSaveData(Gamepad(controls.gamepadsAdded[0]));
      if (padData != null)
      {
        trace('Saving gamepad control scheme to user save');
        Save.instance.setControls(id, Gamepad(controls.gamepadsAdded[0]), padData);
      }
    }
  }
}
