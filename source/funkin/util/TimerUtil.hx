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
   * @param autoDestroy Whether to destroy this sequence after its completion.
   */
  public function new(events:Array<SequenceEvent>, mult:Float = 1, start:Bool = true, autoDestroy:Bool = true)
  {
    this.events = events.copy();

    if (this.events.length == 0) return;

    this.multiplier = Math.max(0, mult);
    this.autoDestroy = autoDestroy;

    this.events.sort((a, b) ->
    {
      // Providing a negative time should make it positive to mimic how FlxTimers work.
      a.time = Math.abs(a.time);
      b.time = Math.abs(b.time);
      return Reflect.compare(a.time, b.time);
    });

    timer.start(currentEvent.time * multiplier, _ ->
    {
      currentEvent.callback();
      eventCount++;

      if (!completed)
      {
        timer.reset((currentEvent.time - events[eventCount - 1].time) * multiplier);
      }
      else if (this.autoDestroy)
      {
        destroy();
      }
    });

    running = start;
  }

  /**
   * The internal timer used by this sequence.
   */
  final timer:FlxTimer = new FlxTimer();

  /**
   * A multiplier for callback times. Useful for frame-based or music-based timing.
   */
  public var multiplier:Float;

  /**
   * The current event being executed. Will be null if this sequence has finished.
   */
  public var currentEvent(get, never):Null<SequenceEvent>;

  inline function get_currentEvent():Null<SequenceEvent>
  {
    return events[eventCount];
  }

  /**
   * The events for this sequence.
   */
  var events:Array<SequenceEvent>;

  /**
   * The amount of currently finished events.
   */
  var eventCount:Int = 0;

  /**
   * Controls whether this sequence is running or not.
   */
  public var running(get, set):Bool;

  function get_running():Bool
  {
    return completed ? false : (timer.active && !timer.finished);
  }

  function set_running(v:Bool):Bool
  {
    if (completed) return false;
    return timer.active = v;
  }

  /**
   * Whether this sequence has completed.
   */
  public var completed(get, never):Bool;

  function get_completed():Bool
  {
    return eventCount >= events.length;
  }

  /**
   * Whether this sequence should be destroyed after completing.
   */
  public var autoDestroy:Bool;

  /**
   * Starts the sequence from the beginning.
   */
  public function start():Void
  {
    if (events.length == 0)
    {
      trace(' WARNING '.bg_yellow().bold() + ' There was an attempt to start a sequence with no events. Was it destroyed?');
      return;
    }
    eventCount = 0;
    timer.reset(currentEvent.time * multiplier);
  }

  /**
   * Cancels out all the events in the sequence.
   */
  public function stop():Void
  {
    eventCount = events.length;
    timer.cancel();
  }

  /**
   * Clean up and destroy this sequence.
   * Note that this will render the sequence unusable.
   */
  public function destroy():Void
  {
    timer.cancel();
    timer.destroy();
    events.clear();
    eventCount = 0;
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

    ArraySort.sort(this.events, function(a:SequenceEvent, b:SequenceEvent):Int
    {
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
