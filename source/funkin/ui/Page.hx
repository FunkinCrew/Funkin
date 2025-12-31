package funkin.ui;

import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.util.FlxSignal;
import funkin.input.Controls;
import funkin.audio.FunkinSound;

/**
 * A page in a menu system.
 *
 * You can use it on it's own, or handle it with a `Codex`
 */
class Page<T:PageName> extends FlxGroup
{
  public var onSwitch(default, null) = new FlxTypedSignal<T->Void>();
  public var onExit(default, null) = new FlxSignal();

  public var enabled(default, set) = true;
  public var canExit = true;

  public var codex:Codex<T>;

  var controls(get, never):Controls;

  inline function get_controls()
    return PlayerSettings.player1.controls;

  var subState:FlxSubState;

  inline function switchPage(name:T)
  {
    onSwitch.dispatch(name);
  }

  function exit()
  {
    onExit.dispatch();
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (enabled) updateEnabled(elapsed);
  }

  function updateEnabled(elapsed:Float)
  {
    if (canExit && controls.BACK)
    {
      exit();
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
    }
  }

  function set_enabled(value:Bool)
  {
    return this.enabled = value;
  }

  function openPrompt(prompt:Prompt, onClose:Void->Void)
  {
    enabled = false;
    prompt.closeCallback = function() {
      enabled = true;
      if (onClose != null) onClose();
    }

    FlxG.state.openSubState(prompt);
  }

  override function destroy()
  {
    super.destroy();
    onSwitch.removeAll();
  }
}

/**
 * For you to fill in your own page name stuff, see OptionsState.hx and it's OptionsMenuPageName
 */
enum abstract PageName(String) from String to String {}
