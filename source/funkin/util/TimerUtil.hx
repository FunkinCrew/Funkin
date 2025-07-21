package funkin.util;

import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import funkin.Conductor;
import haxe.ds.ArraySort;

/**
 * A data structure representing a sequence event.
 */
typedef SequenceEvent =
{
  /**
   * The time in seconds to wait before triggering the event.
   */
  time:Float,

  /**
   * The callback to run when the event is triggered.
   */
  callback:() -> Void
};

/**
 * A timer-based event sequence.
 */
@:nullSafety
class Sequence
{
  /**
   * Create a new sequence.
   * @param events A list of `SequenceEvent`s.
   * @param mult Optional multiplier for callback times. Useful for frame-based or music-based timing.
   * @param start Whether to immediately start the sequence.
   */
  public function new(events:Array<SequenceEvent>, mult:Float = 1, start:Bool = true)
  {
    if (events.length == 0) return;

    mult = Math.max(0, mult);

    for (event in events)
    {
      timers.push(new FlxTimer().start(event.time * mult, function(timer:FlxTimer) {
        event.callback();
        timers.remove(timer);
      }));
    }

    running = start;
  }

  /**
   * The list of uncompleted timers for their respective events.
   */
  final timers:Array<FlxTimer> = [];

  /**
   * Controls whether this sequence is running or not.
   */
  public var running(get, set):Bool;

  var _running:Bool = false;

  function get_running():Bool
  {
    return completed ? false : _running;
  }

  function set_running(v:Bool):Bool
  {
    if (completed) return false;
    for (timer in timers)
    {
      timer.active = v;
    }
    _running = v;
    return _running;
  }

  /**
   * Whether this sequence has completed.
   */
  public var completed(get, never):Bool;

  function get_completed():Bool
  {
    return timers.length == 0;
  }

  /**
   * Clean up and destroy this sequence.
   */
  public function destroy():Void
  {
    while (!completed)
    {
      var timer:Null<FlxTimer> = timers.pop();
      timer?.cancel();
      timer?.destroy();
    }
  }
}

/**
 * A song-based event sequence.
 */
@:nullSafety
class SongSequence
{
  /**
   * Signal dispatched by `Conductor.instance.update`.
   */
  static final update:FlxSignal = new FlxSignal();

  /**
   * Create a new sequence.
   * @param events A list of `SequenceEvent`s.
   * @param mult Optional multiplier for callback times. Useful for frame-based or music-based timing.
   * @param start Whether or not to immediately start the sequence.
   */
  public function new(events:Array<SequenceEvent>, mult:Float = 1, start:Bool = true)
  {
    if (events.length == 0) return;

    mult = Math.max(0, mult);

    for (event in events)
    {
      event.time *= mult * 1000;
      this.events.push(event);
    }

    ArraySort.sort(this.events, function(a:SequenceEvent, b:SequenceEvent):Int {
      if (a.time < b.time) return -1;
      if (a.time > b.time) return 1;
      return 0;
    });

    running = start;
    update.add(onUpdate);
  }

  /**
   * Keeps track of the time this sequence started, or the relative time if it was previously stopped.
   */
  var startTime:Float = 0;

  /**
   * The list of uncompleted events.
   */
  final events:Array<SequenceEvent> = [];

  /**
   * Update function invoked by the update signal.
   */
  function onUpdate():Void
  {
    if (!running) return;
    while (events.length > 0 && events[0].time + startTime <= Conductor.instance.songPosition)
    {
      events.shift()?.callback();
    }
    if (completed) destroy();
  }

  /**
   * Controls whether this sequence is running.
   */
  public var running(get, set):Bool;

  var _running:Bool = false;

  function get_running():Bool
  {
    return _running && !completed;
  }

  function set_running(v:Bool):Bool
  {
    if (completed) return false;
    if (v != _running) startTime = Conductor.instance.songPosition - startTime; // it works trust me
    _running = v;
    return _running;
  }

  /**
   * Whether this sequence has completed.
   */
  public var completed(get, never):Bool;

  function get_completed():Bool
  {
    return events.length == 0;
  }

  /**
   * Clean up and destroy this sequence.
   */
  public function destroy():Void
  {
    update.remove(onUpdate);
    while (!completed)
    {
      events.pop();
    }
  }
}
