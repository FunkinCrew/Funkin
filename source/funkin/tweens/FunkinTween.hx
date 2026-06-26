package funkin.tweens;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.tweens.misc.VarTween;
import flixel.tweens.motion.QuadPath;
import flixel.tweens.motion.Motion;
import flixel.util.FlxDestroyUtil;
import funkin.Conductor;

typedef FunkinTweenOptions =
{
  > TweenOptions,

  @:optional var shouldUseConductorSync:Bool;

  @:optional var conductor:Conductor;

  @:optional var lengthMs:Float;
}

class ConductorSyncHelper
{
  public var shouldUseConductorSync:Bool = false;
  public var startMs:Null<Float> = null;
  public var endMs:Null<Float> = null;
  var _lastSongPositionMs:Null<Float> = null;

  public function new() {}

  public function init(options:FunkinTweenOptions):Void
  {
    if (options == null) return;
    shouldUseConductorSync = options.shouldUseConductorSync == true;
    startMs = options.conductor != null ? options.conductor.songPosition : null;
    endMs = (options.lengthMs != null && startMs != null) ? startMs + options.lengthMs : null;
  }

  public function conductorProgress():Null<Float>
  {
    if (!shouldUseConductorSync || startMs == null || endMs == null || Conductor.instance == null)
    {
      _lastSongPositionMs = null;
      return null;
    }

    var songPositionMs:Float = Conductor.instance.songPosition;

    if (_lastSongPositionMs == null)
    {
      _lastSongPositionMs = songPositionMs;
      return null;
    }

    _lastSongPositionMs = songPositionMs;

    var spanMs:Float = endMs - startMs;
    if (spanMs <= 0) return null;

    var rawProgress:Float = (songPositionMs - startMs) / spanMs;
    return Math.max(0.0, Math.min(1.0, rawProgress));
  }

  public function reset():Void
  {
    _lastSongPositionMs = null;
  }

  public function destroy():Void
  {
    startMs = null;
    endMs = null;
    _lastSongPositionMs = null;
  }
}

class FunkinTween extends FlxTween
{
  public static function createTween(object:Dynamic, values:Dynamic, ?options:FunkinTweenOptions):FunkinVarTween
  {
    var tween = new FunkinVarTween(options);
    var durationSeconds:Float = (options != null && options.lengthMs != null) ? options.lengthMs / 1000.0 : 1.0;
    tween.tween(object, values, durationSeconds);
    return FlxTween.globalManager.add(tween);
  }

  var _sync:ConductorSyncHelper = new ConductorSyncHelper();

  public var shouldUseConductorSync(get, never):Bool;
  public var startMs(get, never):Null<Float>;
  public var endMs(get, never):Null<Float>;

  function get_shouldUseConductorSync() return _sync.shouldUseConductorSync;
  function get_startMs() return _sync.startMs;
  function get_endMs() return _sync.endMs;

  function new(?options:FunkinTweenOptions, ?manager:FlxTweenManager)
  {
    super(options, manager != null ? manager : FlxTween.globalManager);
    _sync.init(options);
  }

  override function update(elapsed:Float):Void
  {
    var rawProgress = _sync.conductorProgress();
    if (rawProgress == null)
    {
      super.update(elapsed);
      return;
    }

    var delta:Float = rawProgress * duration - _secondsSinceStart;
    _secondsSinceStart = rawProgress * duration;
    super.update(0);

    var delay:Float = (executions > 0) ? loopDelay : startDelay;
    if (onUpdate != null && delta != 0 && _secondsSinceStart < duration + delay)
    {
      onUpdate(this);
    }
  }

  public function resetConductorSync():Void
  {
    _sync.reset();
    _running = false;
    finished = false;
  }

  override public function destroy():Void
  {
    super.destroy();
    _sync.destroy();
  }
}

class FunkinVarTween extends VarTween
{
  var _sync:ConductorSyncHelper = new ConductorSyncHelper();

  public var shouldUseConductorSync(get, never):Bool;
  public var startMs(get, never):Null<Float>;
  public var endMs(get, never):Null<Float>;

  function get_shouldUseConductorSync() return _sync.shouldUseConductorSync;
  function get_startMs() return _sync.startMs;
  function get_endMs() return _sync.endMs;

  public function new(?options:FunkinTweenOptions, ?manager:FlxTweenManager)
  {
    super(options, manager != null ? manager : FlxTween.globalManager);
    _sync.init(options);
  }

  override function update(elapsed:Float):Void
  {
    var rawProgress = _sync.conductorProgress();
    if (rawProgress == null)
    {
      super.update(elapsed);
      return;
    }

    var delta:Float = rawProgress * duration - _secondsSinceStart;
    _secondsSinceStart = rawProgress * duration;
    super.update(0);

    var delay:Float = (executions > 0) ? loopDelay : startDelay;
    if (onUpdate != null && delta != 0 && _secondsSinceStart < duration + delay)
    {
      onUpdate(this);
    }
  }

  public function resetConductorSync():Void
  {
    _sync.reset();
    _running = false;
    finished = false;
  }

  override public function destroy():Void
  {
    super.destroy();
    _sync.destroy();
  }
}
