package funkin;

import funkin.save.Save;
import funkin.Controls;
import flixel.FlxCamera;
import funkin.input.PreciseInputManager;
import flixel.input.actions.FlxActionInput;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxSignal;

/**
 * A core class which represents the current player(s) and their controls and other configuration.
 */
class PlayerSettings
{
  public static var numPlayers(default, null) = 0;
  public static var numAvatars(default, null) = 0;
  public static var player1(default, null):PlayerSettings;
  public static var player2(default, null):PlayerSettings;

  public static var onAvatarAdd(default, null) = new FlxTypedSignal<PlayerSettings->Void>();
  public static var onAvatarRemove(default, null) = new FlxTypedSignal<PlayerSettings->Void>();

  public var id(default, null):Int;

  public var controls(default, null):Controls;

  /**
   * Return the PlayerSettings for the given player number, or `null` if that player isn't active.
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

  public static function reset()
  {
    player1 = null;
    player2 = null;
    numPlayers = 0;
  }

  static function onGamepadAdded(gamepad:FlxGamepad)
  {
    player1.addGamepad(gamepad);
  }

  /**
   * @param id The player number this represents. This was refactored to START AT `1`.
   */
  private function new(id:Int)
  {
    trace('loading player settings for id: $id');

    this.id = id;
    this.controls = new Controls('player$id', None);

    addKeyboard();
  }

  function addKeyboard():Void
  {
    var useDefault = true;
    if (Save.get().hasControls(id, Keys))
    {
      var keyControlData = Save.get().getControls(id, Keys);
      trace("keyControlData: " + haxe.Json.stringify(keyControlData));
      useDefault = false;
      controls.fromSaveData(keyControlData, Keys);
    }
    else
    {
      useDefault = true;
    }

    if (useDefault)
    {
      trace("Loading default keyboard control scheme");
      controls.setKeyboardScheme(Solo);
    }

    PreciseInputManager.instance.initializeKeys(controls);
  }

  /**
   * Called after an FlxGamepad has been detected.
   * @param gamepad The gamepad that was detected.
   */
  function addGamepad(gamepad:FlxGamepad)
  {
    var useDefault = true;
    if (Save.get().hasControls(id, Gamepad(gamepad.id)))
    {
      var padControlData = Save.get().getControls(id, Gamepad(gamepad.id));
      trace("padControlData: " + haxe.Json.stringify(padControlData));
      useDefault = false;
      controls.addGamepadWithSaveData(gamepad.id, padControlData);
    }
    else
    {
      useDefault = true;
    }

    if (useDefault)
    {
      trace("Loading gamepad control scheme");
      controls.addDefaultGamepad(gamepad.id);
    }
    PreciseInputManager.instance.initializeButtons(controls, gamepad);
  }

  /**
   * Save this player's controls to the game's persistent save.
   */
  public function saveControls()
  {
    var keyData = controls.createSaveData(Keys);
    if (keyData != null)
    {
      trace("saving key data: " + haxe.Json.stringify(keyData));
      Save.get().setControls(id, Keys, keyData);
    }

    if (controls.gamepadsAdded.length > 0)
    {
      var padData = controls.createSaveData(Gamepad(controls.gamepadsAdded[0]));
      if (padData != null)
      {
        trace("saving pad data: " + haxe.Json.stringify(padData));
        Save.get().setControls(id, Gamepad(controls.gamepadsAdded[0]), padData);
      }
    }
  }
}
