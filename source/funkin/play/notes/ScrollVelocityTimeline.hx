package funkin.play.notes;

import flixel.tweens.FlxEase;
import funkin.data.song.SongData.SongEventData;
import funkin.play.event.ScrollVelocityEvent;
import funkin.play.event.SongEvent;

/**
 * The Scroll Velocity events of a chart for one strumline.
 */
@:nullSafety
class ScrollVelocityTimeline
{
  static final INTEGRATE_SLICES:Int = 32;

  /**
   * How close to 1x counts as back to normal.
   */
  static final NORMAL_VELOCITY_RANGE:Float = 0.0001;

  /**
   * The velocity over the song.
   */
  public var segments(default, null):Array<ScrollVelocitySegment> = [];

  var rawStarts:Array<Float> = [];
  var stretches:Array<VelocityStretch> = [];

  /**
   * @param events The chart's events.
   * @param strumline `player` or `opponent`.
   * @param conductor Used for the length of a step. Defaults to `Conductor.instance`.
   */
  public function new(events:Array<SongEventData>, strumline:String, ?conductor:Conductor)
  {
    var stepConductor:Conductor = conductor ?? Conductor.instance;
    segments = [
      {
        time: 0,
        from: 1,
        to: 1,
        duration: 0,
        ease: null
      }
    ];

    var velocityEvents:Array<SongEventData> = [for (event in events) if (event.eventKind == 'ScrollVelocity') event];
    haxe.ds.ArraySort.sort(velocityEvents, (a, b) -> (a.time < b.time) ? -1 : ((a.time > b.time) ? 1 : 0));

    for (event in velocityEvents)
    {
      var target:String = event.getString('strumline') ?? ScrollVelocityEvent.DEFAULT_STRUMLINE;
      if (target != 'both' && target != strumline) continue;

      var time:Float = Math.max(0, event.time);

      // Later events cut off the ones before them.
      while (segments.length > 1 && segments[segments.length - 1].time > time)
        segments.pop();

      var from:Float = velocityAt(time);

      // Below 0 the notes move back up, away from the strums.
      var velocity:Float = event.getFloat('velocity') ?? ScrollVelocityEvent.DEFAULT_VELOCITY;
      var ease:String = event.getString('ease') ?? SongEvent.DEFAULT_EASE;
      var easeDir:String = event.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;
      if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == 'linear') easeDir = '';
      var easeFunction:Null<Float->Float> = (ease == 'INSTANT') ? null : Reflect.field(FlxEase, '$ease$easeDir');
      var steps:Float = event.getFloat('duration') ?? ScrollVelocityEvent.DEFAULT_DURATION;
      var duration:Float = 0;
      if (easeFunction != null && steps > 0)
      {
        var step:Float = stepConductor.getTimeInSteps(time);
        duration = steps * (stepConductor.getStepTimeInMs(step + 1) - stepConductor.getStepTimeInMs(step));
      }

      segments.push({
        time: time,
        from: from,
        to: velocity,
        duration: duration,
        ease: (duration > 0) ? easeFunction : null
      });
    }

    rawStarts = [0];
    for (i in 1...segments.length)
    {
      var previous:ScrollVelocitySegment = segments[i - 1];
      rawStarts.push(rawStarts[i - 1] + integrate(previous, previous.time, segments[i].time));
    }

    buildStretches();
  }

  static function isNormal(velocity:Float):Bool
  {
    return Math.abs(velocity - 1) <= NORMAL_VELOCITY_RANGE;
  }

  /**
   * Find each stretch away from 1x and how far off the notes would be at its end.
   */
  function buildStretches():Void
  {
    stretches = [];
    var index:Int = 1;
    while (index < segments.length)
    {
      if (isNormal(segments[index].to))
      {
        index++;
        continue;
      }

      var start:Float = segments[index].time;
      var back:Int = index + 1;
      while (back < segments.length && !isNormal(segments[back].to))
        back++;

      if (back >= segments.length)
      {
        stretches.push({
          start: start,
          returnStart: Math.POSITIVE_INFINITY,
          end: Math.POSITIVE_INFINITY,
          returnEase: null,
          add: 0
        });
        break;
      }

      var returning:ScrollVelocitySegment = segments[back];
      var end:Float = returning.time + returning.duration;
      if (back + 1 < segments.length) end = Math.min(end, segments[back + 1].time);

      stretches.push({
        start: start,
        returnStart: returning.time,
        end: end,
        returnEase: returning.ease,
        add: (end - start) - (rawTime(end) - rawTime(start))
      });
      index = back + 1;
    }
  }

  public var hasEvents(get, never):Bool;

  function get_hasEvents():Bool
  {
    return segments.length > 1;
  }

  public static function velocityOf(segment:ScrollVelocitySegment, time:Float):Float
  {
    var ease:Null<Float->Float> = segment.ease;
    if (ease == null || segment.duration <= 0 || time >= segment.time + segment.duration) return segment.to;
    if (time <= segment.time) return segment.from;
    return segment.from + (segment.to - segment.from) * ease((time - segment.time) / segment.duration);
  }

  /**
   * Integrates the velocity of a segment over a time range, returning the total distance traveled.
   * @param segment The segment to integrate.
   * @param from The start time of the range.
   * @param to The end time of the range.
   * @return Float
   */
  static function integrate(segment:ScrollVelocitySegment, from:Float, to:Float):Float
  {
    if (to <= from) return 0;
    if (segment.ease == null || segment.duration <= 0) return segment.to * (to - from);
    var easeEnd:Float = Math.min(to, segment.time + segment.duration);
    var total:Float = 0;
    if (easeEnd > from)
    {
      var slice:Float = (easeEnd - from) / INTEGRATE_SLICES;
      for (i in 0...INTEGRATE_SLICES)
        total += velocityOf(segment, from + slice * (i + 0.5)) * slice;
    }
    if (to > easeEnd) total += segment.to * (to - Math.max(easeEnd, from));
    return total;
  }

  function segmentIndexAt(time:Float):Int
  {
    var low:Int = 0;
    var high:Int = segments.length - 1;
    while (low < high)
    {
      var mid:Int = (low + high + 1) >> 1;
      if (segments[mid].time <= time) low = mid;
      else
        high = mid - 1;
    }
    return low;
  }

  /**
   * The velocity added up from the start of the song, before any catch-up.
   */
  function rawTime(time:Float):Float
  {
    var index:Int = segmentIndexAt(time);
    var segment:ScrollVelocitySegment = segments[index];
    return rawStarts[index] + integrate(segment, segment.time, time);
  }

  /**
   * The velocity at a song time.
   */
  public function velocityAt(time:Float):Float
  {
    return velocityOf(segments[segmentIndexAt(time)], time);
  }

  /**
   * The song time the notes are drawn around at a real song time.
   */
  public function visualTime(time:Float):Float
  {
    if (!hasEvents || time <= 0) return time;
    for (stretch in stretches)
    {
      if (time < stretch.start) break;
      if (time >= stretch.end) continue;

      var visual:Float = stretch.start + rawTime(time) - rawTime(stretch.start);
      if (time < stretch.returnStart) return visual;

      var length:Float = stretch.end - stretch.returnStart;
      var progress:Float = 1;
      var ease:Null<Float->Float> = stretch.returnEase;
      if (length > 0) progress = (ease != null) ? ease((time - stretch.returnStart) / length) : (time - stretch.returnStart) / length;
      return visual + stretch.add * progress;
    }
    // Outside every stretch the velocity is 1x and the notes are on time.
    return time;
  }
}

/**
 * The velocity from one event until the next.
 */
typedef ScrollVelocitySegment =
{
  var time:Float;
  var from:Float;
  var to:Float;
  var duration:Float;
  var ease:Null<Float->Float>;
}

/**
 * A stretch where the velocity isn't 1x.
 */
typedef VelocityStretch =
{
  var start:Float;

  var returnStart:Float;
  var end:Float;
  var returnEase:Null<Float->Float>;

  var add:Float;
}
