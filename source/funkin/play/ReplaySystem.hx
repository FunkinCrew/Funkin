package funkin.play;

import haxe.crypto.Sha256;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.Int64;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.utils.Bytes;
import openfl.ui.Keyboard;
import funkin.play.notes.NoteDirection;
import funkin.input.PreciseInputManager;
import funkin.Conductor;
import funkin.util.Constants;
import funkin.input.Controls;
import funkin.Preferences;
import flixel.input.keyboard.FlxKey;
import flixel.input.actions.FlxActionInput;
import flixel.FlxG;
import Date;

class ReplaySystem
{
  public var bytes(get, null):Bytes = null;

  var data:ReplayData = null;

  var isRecording:Bool = false;
  var isPlaying:Bool = false;

  var songPosition(get, never):Int64;

  public function new(id:String, variation:String, difficulty:String)
  {
    this.data = new ReplayData(id, variation, difficulty, Preferences.framerate, []);
  }

  public function update(elapsed:Float):Void
  {
    if (!isPlaying)
    {
      return;
    }

    var songPosition:Int64 = songPosition;
    for (input in data.inputs)
    {
      if (songPosition >= input.timestamp)
      {
        var keyCodes:Array<KeyCode> = [];
        for (action in input.actions)
        {
          var key:FlxKey = PlayerSettings.player1.controls.getKeysForAction(action)[0];
          keyCodes.pushUnique(convertToKeyCode(key));
        }

        // timestamp needs to be in milliseconds here
        // because onKey...Precise expects milliseconds
        var timestampNS:Int64 = input.timestamp + PreciseInputManager.getCurrentTimestamp() - songPosition;
        var timestamp:Int64 = timestampNS / Constants.NS_PER_MS;

        if (input.isRelease)
        {
          for (keyCode in keyCodes)
          {
            FlxG.stage.application.window.onKeyUp.dispatch(keyCode, KeyModifier.NONE);
            FlxG.stage.application.window.onKeyUpPrecise.dispatch(keyCode, KeyModifier.NONE, timestamp);
          }
        }
        else
        {
          for (keyCode in keyCodes)
          {
            FlxG.stage.application.window.onKeyDown.dispatch(keyCode, KeyModifier.NONE);
            FlxG.stage.application.window.onKeyDownPrecise.dispatch(keyCode, KeyModifier.NONE, timestamp);
          }
        }

        data.inputs.remove(input);
      }
    }
  }

  public function startRecording():Void
  {
    isRecording = true;
    isPlaying = false;
    data.inputs = [];

    FlxG.stage.application.window.onKeyDownPrecise.add(pressedInput);
    FlxG.stage.application.window.onKeyUpPrecise.add(releasedInput);
  }

  public function stopRecording():Void
  {
    isRecording = false;

    FlxG.stage.application.window.onKeyDownPrecise.remove(pressedInput);
    FlxG.stage.application.window.onKeyUpPrecise.remove(releasedInput);
  }

  public function startPlaying(inputs:Array<ReplayInput>):Void
  {
    isPlaying = true;
    isRecording = false;
    data.inputs = inputs;
  }

  public function stopPlaying():Void
  {
    isPlaying = false;
  }

  public function saveReplay():Void
  {
    #if sys
    if (!sys.FileSystem.exists('replays'))
    {
      sys.FileSystem.createDirectory('replays');
    }

    var date:Date = Date.now();

    var timeString:String = '${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}_${date.getHours()}-${date.getMinutes()}-${date.getSeconds()}';
    var dataString:String = '${data.id}-${data.variation}-${data.difficulty}';

    sys.io.File.saveBytes('replays/${timeString}_${dataString}.fnfr', bytes);
    #else
    trace('ERROR: saveReplay is not implemented for this platform');
    return;
    #end
  }

  function pressedInput(key:KeyCode, modifier:KeyModifier, _:Int64):Void
  {
    var timestamp:Int64 = songPosition;
    data.inputs.push(
      {
        actions: getActionsForKey(convertToFlxKey(key)),
        timestamp: timestamp,
        isRelease: false
      });
  }

  function releasedInput(key:KeyCode, modifier:KeyModifier, _:Int64):Void
  {
    var timestamp:Int64 = songPosition;
    data.inputs.push(
      {
        actions: getActionsForKey(convertToFlxKey(key)),
        timestamp: timestamp,
        isRelease: true
      });
  }

  function get_bytes():Bytes
  {
    if (bytes != null)
    {
      return bytes;
    }

    bytes = data.toBytes();

    return bytes;
  }

  function get_songPosition():Int64
  {
    return cast((Conductor.instance.songPosition - Conductor.instance.inputOffset - Conductor.instance.instrumentalOffset) * Constants.NS_PER_MS);
  }

  static function getActionsForKey(key:FlxKey):Array<Action>
  {
    var actions:Array<Action> = [];
    for (action in PlayerSettings.player1.controls.digitalActions)
    {
      for (input in action.inputs)
      {
        if (input.device != FlxInputDevice.KEYBOARD)
        {
          continue;
        }

        var keys:Array<FlxKey> = PlayerSettings.player1.controls.getKeysForAction(action.name);
        if (keys.contains(key))
        {
          actions.pushUnique(action.name);
          break;
        }
      }
    }

    return actions;
  }

  static function convertToFlxKey(key:KeyCode):FlxKey
  {
    @:privateAccess
    return Keyboard.__convertKeyCode(key);
  }

  /**
   * Basically just the inverse of Keyboard.__convertKeyCode
   */
  static function convertToKeyCode(key:FlxKey):KeyCode
  {
    var code:Int = cast key;
    return switch (code)
    {
      case Keyboard.BACKSPACE: KeyCode.BACKSPACE;
      case Keyboard.TAB: KeyCode.TAB;
      case Keyboard.ENTER: KeyCode.RETURN;
      case Keyboard.ESCAPE: KeyCode.ESCAPE;
      case Keyboard.SPACE: KeyCode.SPACE;
      case Keyboard.NUMBER_1: KeyCode.EXCLAMATION;
      case Keyboard.QUOTE: KeyCode.QUOTE;
      case Keyboard.NUMBER_3: KeyCode.HASH;
      case Keyboard.NUMBER_4: KeyCode.DOLLAR;
      case Keyboard.NUMBER_5: KeyCode.PERCENT;
      case Keyboard.NUMBER_7: KeyCode.AMPERSAND;
      case Keyboard.NUMBER_9: KeyCode.LEFT_PARENTHESIS;
      case Keyboard.NUMBER_0: KeyCode.RIGHT_PARENTHESIS;
      case Keyboard.NUMBER_8: KeyCode.ASTERISK;
      case Keyboard.COMMA: KeyCode.COMMA;
      case Keyboard.MINUS: KeyCode.MINUS;
      case Keyboard.PERIOD: KeyCode.PERIOD;
      case Keyboard.SLASH: KeyCode.SLASH;
      case Keyboard.NUMBER_2: KeyCode.NUMBER_2;
      case Keyboard.NUMBER_6: KeyCode.NUMBER_6;
      case Keyboard.SEMICOLON: KeyCode.COLON;
      case Keyboard.EQUAL: KeyCode.EQUALS;
      case Keyboard.SLASH: KeyCode.QUESTION;
      case Keyboard.NUMBER_2: KeyCode.AT;
      case Keyboard.LEFTBRACKET: KeyCode.LEFT_BRACKET;
      case Keyboard.BACKSLASH: KeyCode.BACKSLASH;
      case Keyboard.RIGHTBRACKET: KeyCode.RIGHT_BRACKET;
      case Keyboard.NUMBER_6: KeyCode.CARET;
      case Keyboard.MINUS: KeyCode.UNDERSCORE;
      case Keyboard.BACKQUOTE: KeyCode.GRAVE;
      case Keyboard.A: KeyCode.A;
      case Keyboard.B: KeyCode.B;
      case Keyboard.C: KeyCode.C;
      case Keyboard.D: KeyCode.D;
      case Keyboard.E: KeyCode.E;
      case Keyboard.F: KeyCode.F;
      case Keyboard.G: KeyCode.G;
      case Keyboard.H: KeyCode.H;
      case Keyboard.I: KeyCode.I;
      case Keyboard.J: KeyCode.J;
      case Keyboard.K: KeyCode.K;
      case Keyboard.L: KeyCode.L;
      case Keyboard.M: KeyCode.M;
      case Keyboard.N: KeyCode.N;
      case Keyboard.O: KeyCode.O;
      case Keyboard.P: KeyCode.P;
      case Keyboard.Q: KeyCode.Q;
      case Keyboard.R: KeyCode.R;
      case Keyboard.S: KeyCode.S;
      case Keyboard.T: KeyCode.T;
      case Keyboard.U: KeyCode.U;
      case Keyboard.V: KeyCode.V;
      case Keyboard.W: KeyCode.W;
      case Keyboard.X: KeyCode.X;
      case Keyboard.Y: KeyCode.Y;
      case Keyboard.Z: KeyCode.Z;
      case Keyboard.DELETE: KeyCode.DELETE;
      case Keyboard.CAPS_LOCK: KeyCode.CAPS_LOCK;
      case Keyboard.F1: KeyCode.F1;
      case Keyboard.F2: KeyCode.F2;
      case Keyboard.F3: KeyCode.F3;
      case Keyboard.F4: KeyCode.F4;
      case Keyboard.F5: KeyCode.F5;
      case Keyboard.F6: KeyCode.F6;
      case Keyboard.F7: KeyCode.F7;
      case Keyboard.F8: KeyCode.F8;
      case Keyboard.F9: KeyCode.F9;
      case Keyboard.F10: KeyCode.F10;
      case Keyboard.F11: KeyCode.F11;
      case Keyboard.F12: KeyCode.F12;
      case Keyboard.BREAK: KeyCode.PAUSE;
      case Keyboard.INSERT: KeyCode.INSERT;
      case Keyboard.HOME: KeyCode.HOME;
      case Keyboard.PAGE_UP: KeyCode.PAGE_UP;
      case Keyboard.END: KeyCode.END;
      case Keyboard.PAGE_DOWN: KeyCode.PAGE_DOWN;
      case Keyboard.RIGHT: KeyCode.RIGHT;
      case Keyboard.LEFT: KeyCode.LEFT;
      case Keyboard.DOWN: KeyCode.DOWN;
      case Keyboard.UP: KeyCode.UP;
      case Keyboard.NUMLOCK: KeyCode.NUM_LOCK;
      case Keyboard.NUMPAD_DIVIDE: KeyCode.NUMPAD_DIVIDE;
      case Keyboard.NUMPAD_MULTIPLY: KeyCode.NUMPAD_MULTIPLY;
      case Keyboard.NUMPAD_SUBTRACT: KeyCode.NUMPAD_MINUS;
      case Keyboard.NUMPAD_ADD: KeyCode.NUMPAD_PLUS;
      case Keyboard.NUMPAD_ENTER: #if openfl_numpad_enter KeyCode.NUMPAD_ENTER #else KeyCode.RETURN2 #end;
      case Keyboard.NUMPAD_1: KeyCode.NUMPAD_1;
      case Keyboard.NUMPAD_2: KeyCode.NUMPAD_2;
      case Keyboard.NUMPAD_3: KeyCode.NUMPAD_3;
      case Keyboard.NUMPAD_4: KeyCode.NUMPAD_4;
      case Keyboard.NUMPAD_5: KeyCode.NUMPAD_5;
      case Keyboard.NUMPAD_6: KeyCode.NUMPAD_6;
      case Keyboard.NUMPAD_7: KeyCode.NUMPAD_7;
      case Keyboard.NUMPAD_8: KeyCode.NUMPAD_8;
      case Keyboard.NUMPAD_9: KeyCode.NUMPAD_9;
      case Keyboard.NUMPAD_0: KeyCode.NUMPAD_0;
      case Keyboard.NUMPAD_DECIMAL: KeyCode.NUMPAD_PERIOD;
      case Keyboard.F13: KeyCode.F13;
      case Keyboard.F14: KeyCode.F14;
      case Keyboard.F15: KeyCode.F15;
      case Keyboard.CONTROL: KeyCode.LEFT_CTRL;
      case Keyboard.SHIFT: KeyCode.LEFT_SHIFT;
      case Keyboard.ALTERNATE: KeyCode.LEFT_ALT;
      case Keyboard.COMMAND: KeyCode.LEFT_META;
      default: cast key;
    }
  }
}

class ReplayData
{
  static final SHA256_LENGTH:Int = 32;

  public var id:String;
  public var variation:String;
  public var difficulty:String;
  public var framerate:Int;
  public var inputs:Array<ReplayInput>;

  public function new(id:String, variation:String, difficulty:String, framerate:Int, inputs:Array<ReplayInput>)
  {
    this.id = id;
    this.variation = variation;
    this.difficulty = difficulty;
    this.framerate = framerate;
    this.inputs = inputs;
  }

  public static function fromBytes(bytes:Bytes):ReplayData
  {
    var storedSha:Bytes = bytes.sub(bytes.length - SHA256_LENGTH, SHA256_LENGTH);

    var storedData:Bytes = bytes.sub(0, bytes.length - SHA256_LENGTH);
    var generatedSha = Sha256.make(storedData);

    var shaResult:Int = storedSha.compare(generatedSha);
    if (shaResult != 0)
    {
      throw 'Invalid replay file!\nSomeone most likely tampered with it.\nResult: ${shaResult}';
    }

    var buffer:BytesInput = new BytesInput(bytes);
    var id:String = buffer.readString(buffer.readInt32());
    var variation:String = buffer.readString(buffer.readInt32());
    var difficulty:String = buffer.readString(buffer.readInt32());
    var framerate:Int = buffer.readInt32();

    var inputs:Array<ReplayInput> = [];
    for (_ in 0...buffer.readInt32())
    {
      var actions:Array<Action> = [];
      for (_ in 0...buffer.readInt32())
      {
        var action:Action = buffer.readString(buffer.readInt32());
        actions.push(action);
      }
      var timestamp:Int64 = readInt64(buffer);
      var isRelease:Bool = cast buffer.readByte();

      inputs.push(
        {
          actions: actions,
          timestamp: timestamp,
          isRelease: isRelease
        });
    }

    return new ReplayData(id, variation, difficulty, framerate, inputs);
  }

  public function toBytes():Bytes
  {
    var buffer:BytesBuffer = new BytesBuffer();

    buffer.addInt32(id.length);
    buffer.addString(id);
    buffer.addInt32(variation.length);
    buffer.addString(variation);
    buffer.addInt32(difficulty.length);
    buffer.addString(difficulty);
    buffer.addInt32(framerate);
    buffer.addInt32(inputs.length);
    for (input in inputs)
    {
      buffer.addInt32(input.actions.length);
      for (action in input.actions)
      {
        var actionStr:String = cast action;
        buffer.addInt32(actionStr.length);
        buffer.addString(actionStr);
      }
      buffer.addInt64(input.timestamp);
      buffer.addByte(cast input.isRelease);
    }

    var bytes = buffer.getBytes();
    var sha = Sha256.make(bytes);

    buffer = new BytesBuffer();
    buffer.add(bytes);
    buffer.add(sha);

    return buffer.getBytes();
  }

  static function readInt64(buffer:BytesInput):Int64
  {
    var low:Int = buffer.readInt32();
    var high:Int = buffer.readInt32();
    return Int64.make(high, low);
  }
}

typedef ReplayInput =
{
  var actions:Array<Action>;
  var timestamp:Int64;
  var isRelease:Bool;
}
