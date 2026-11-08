package funkin.ui.debug.charting.util;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;

@:allow(funkin.ui.debug.charting.ChartEditorState)
@:allow(funkin.ui.debug.charting.handlers.ui.ChartEditorLayoutHandler)
class ChartEditorTimeScale
{
  static final GAME_HEIGHT:Float = 720;

  /**
   * Height of one step on the grid, in pixels. This is `GRID_SIZE` scaled by the current zoom.
   */
  public static var STEP_HEIGHT(default, null):Float = ChartEditorState.GRID_SIZE;

  /**
   * Whether the grid scrolls at the fixed speed from Preferences, ignoring Scroll Speed events.
   */
  public static var CONSTANT_SCROLL(default, null):Bool = false;

  /**
   * At a constant scroll speed of 1x, this many milliseconds take up one step's height.
   */
  public static final CONSTANT_SCROLL_REFERENCE_STEP_MS:Float = 125;

  /**
   * Pixels per millisecond when `CONSTANT_SCROLL` is on.
   */
  public static var PIXELS_PER_MS(default, null):Float = ChartEditorState.GRID_SIZE / CONSTANT_SCROLL_REFERENCE_STEP_MS;

  /**
   * Where a song step is on the grid, in pixels from the top.
   */
  public static function stepToPixels(step:Float):Float
  {
    if (step < 0) return msToPixels(step * firstStepLengthMs());
    return msToPixels(Conductor.instance.getStepTimeInMs(step));
  }

  /**
   * Which song step is at a position on the grid, in pixels from the top.
   */
  public static function pixelsToStep(pixels:Float):Float
  {
    var ms:Float = pixelsToMs(pixels);
    if (ms < 0) return ms / firstStepLengthMs();
    return Conductor.instance.getTimeInSteps(ms);
  }

  /**
   * How long a step is at the song start, used to carry the grid on above it.
   */
  static function firstStepLengthMs():Float
  {
    var length:Float = Conductor.instance.getStepTimeInMs(1) - Conductor.instance.getStepTimeInMs(0);
    return (length > 0) ? length : Conductor.instance.stepLengthMs;
  }

  /**
   * Pixels per millisecond before the scroll speed. Constant scroll takes it from its speed setting.
   */
  static inline function basePixelsPerMs():Float
  {
    return CONSTANT_SCROLL ? PIXELS_PER_MS : Constants.PIXELS_PER_MS * STEP_HEIGHT / funkin.play.notes.Strumline.STRUMLINE_SIZE;
  }

  /**
   * Where a song time is on the grid, in pixels from the top.
   */
  public static function msToPixels(ms:Float):Float
  {
    return (CONSTANT_SCROLL ? ms : scrollSpeedDistance(ms)) * basePixelsPerMs();
  }

  /**
   * Which song time is at a position on the grid, in pixels from the top.
   */
  public static function pixelsToMs(pixels:Float):Float
  {
    var distance:Float = pixels / basePixelsPerMs();
    return CONSTANT_SCROLL ? distance : scrollSpeedTime(distance);
  }

  /**
   * Where a note or event is on the grid.
   */
  public static inline function timeToPixels(ms:Float, stepTime:Float):Float
  {
    return msToPixels(ms);
  }

  /**
   * How tall a hold is on the grid. Needs the start because scroll speed events can change the speed partway through.
   */
  public static inline function lengthToPixels(startMs:Float, lengthMs:Float, stepLength:Float):Float
  {
    return msToPixels(startMs + lengthMs) - msToPixels(startMs);
  }

  /**
   * How tall one step is at the current song position, in pixels.
   */
  public static function currentStepPixels():Float
  {
    var songMs:Float = Conductor.instance.songPosition;
    return msToPixels(songMs + Conductor.instance.stepLengthMs) - msToPixels(songMs);
  }

  /**
   * The scroll speed over the song, from the chart's Scroll Speed events, as points sorted by time.
   */
  static var scrollSpeedPoints:Array<ScrollSpeedPoint> = [{time: 0, distance: 0, speed: 1}];

  /**
   * How many flat pieces an eased scroll speed change is split into.
   */
  static final SCROLL_SPEED_EASE_PIECES:Int = 16;

  /**
   * The slowest speed the map allows, so it can always be turned back into a time.
   */
  static final SCROLL_SPEED_MIN:Float = 0.05;

  /**
   * Rebuild `scrollSpeedPoints` from the chart's scroll speed and its events, the way the game plays them.
   * @return Whether anything changed.
   */
  static function buildScrollSpeedPoints(events:Array<SongEventData>, chartScrollSpeed:Float):Bool
  {
    velocity = new funkin.play.notes.ScrollVelocityTimeline(events, 'player');

    var baseSpeed:Float = (chartScrollSpeed > 0) ? chartScrollSpeed : 1;
    var points:Array<ScrollSpeedPoint> = [{time: 0, distance: 0, speed: baseSpeed}];

    function addPoint(time:Float, speed:Float):Void
    {
      speed = Math.max(speed, SCROLL_SPEED_MIN);
      var last:ScrollSpeedPoint = points[points.length - 1];
      if (time <= last.time)
      {
        last.speed = speed;
        return;
      }
      points.push({time: time, distance: last.distance + (time - last.time) * last.speed, speed: speed});
    }

    var speedEvents:Array<SongEventData> = [for (event in events) if (event.eventKind == 'ScrollSpeed') event];
    speedEvents.sort((a, b) -> (a.time < b.time) ? -1 : ((a.time > b.time) ? 1 : 0));
    gameSpeedBase = baseSpeed;
    gameSpeedChanges = [];

    var target:Float = baseSpeed;
    for (event in speedEvents)
    {
      if ((event.getString('strumline') ?? 'both') == 'opponent') continue;

      var time:Float = Math.max(0, event.time);
      var speed:Float = event.getFloat('scroll') ?? 1;
      if (!(event.getBool('absolute') ?? false)) speed *= baseSpeed;

      while (points.length > 1 && points[points.length - 1].time > time)
        points.pop();

      var ease:String = event.getString('ease') ?? funkin.play.event.SongEvent.DEFAULT_EASE;
      var steps:Float = event.getFloat('duration') ?? 4;
      var easeFunction:Null<Float->Float> = null;
      if (ease != 'INSTANT' && steps > 0)
      {
        var easeDir:String = event.getString('easeDir') ?? funkin.play.event.SongEvent.DEFAULT_EASE_DIR;
        if (funkin.play.event.SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == 'linear') easeDir = '';
        easeFunction = Reflect.field(flixel.tweens.FlxEase, '$ease$easeDir');
      }

      var changeDuration:Float = 0;
      if (easeFunction != null)
      {
        var changeStep:Float = event.getStepTime();
        changeDuration = steps * (Conductor.instance.getStepTimeInMs(changeStep + 1) - Conductor.instance.getStepTimeInMs(changeStep));
      }
      gameSpeedChanges.push({
        time: time,
        duration: changeDuration,
        from: target,
        to: speed,
        ease: easeFunction
      });

      if (easeFunction == null)
      {
        addPoint(time, speed);
      }
      else
      {
        var eventStep:Float = event.getStepTime();
        var durationMs:Float = steps * (Conductor.instance.getStepTimeInMs(eventStep + 1) - Conductor.instance.getStepTimeInMs(eventStep));
        for (i in 0...SCROLL_SPEED_EASE_PIECES)
        {
          var progress:Float = easeFunction((i + 0.5) / SCROLL_SPEED_EASE_PIECES);
          addPoint(time + durationMs * i / SCROLL_SPEED_EASE_PIECES, target + (speed - target) * progress);
        }
        addPoint(time + durationMs, speed);
      }
      target = speed;
    }

    var old:Array<ScrollSpeedPoint> = scrollSpeedPoints;
    scrollSpeedPoints = points;
    if (old.length != points.length) return true;
    for (i in 0...points.length)
    {
      if (old[i].time != points[i].time || old[i].speed != points[i].speed) return true;
    }
    return false;
  }


  static var velocity:Null<funkin.play.notes.ScrollVelocityTimeline> = null;
  public static function visualTime(ms:Float):Float
  {
    // Disabled to allow for constant scroll speed to show visual time
    // if (CONSTANT_SCROLL) return ms;
    var line:Null<funkin.play.notes.ScrollVelocityTimeline> = velocity;
    if (line == null) return ms;
    var visual:Float = line.visualTime(ms);
    var start:Float = line.stretchStartAt(ms);
    if (start < 0) return visual;
    return funkin.play.notes.ScrollVelocityTimeline.scaleLag(ms, visual, gameScrollSpeedAt(start), gameScrollSpeedAt(ms));
  }

  public static function hasVelocityOffset(ms:Float):Bool
  {
    return Math.abs(visualTime(ms) - ms) > 0.5;
  }

  /**
   * The chart's scroll speed, and each Scroll Speed event as the game eases it, for the exact speed at a moment.
   */
  static var gameSpeedBase:Float = 1;

  static var gameSpeedChanges:Array<{time:Float, duration:Float, from:Float, to:Float, ease:Null<Float->Float>}> = [];

  /**
   * The scroll speed at a song time, from the chart's Scroll Speed events, as the game plays them.
   */
  public static function gameScrollSpeedAt(ms:Float):Float
  {
    var speed:Float = gameSpeedBase;
    for (change in gameSpeedChanges)
    {
      if (change.time > ms) break;
      var ease:Null<Float->Float> = change.ease;
      if (ease == null || change.duration <= 0 || ms >= change.time + change.duration) speed = change.to;
      else
        speed = change.from + (change.to - change.from) * ease((ms - change.time) / change.duration);
    }
    return speed;
  }

  /**
   * The song time of the notes at the receptors, which can be different from the real song time when Scroll Velocity events have moved them.
   * @param visualMs The song time of the notes at the receptors.
   * @param ms The real song time, which sets the scroll speed.
   * @param downscroll Whether the game is played on downscroll.
   * @param strumlineOffsetY The note style's vertical strumline offset, which only moves the strumline on downscroll.
   */
  public static function playerViewEnd(visualMs:Float, ms:Float, downscroll:Bool = false, strumlineOffsetY:Float = 0):Float
  {
    var pixelsPerMs:Float = Constants.PIXELS_PER_MS * Math.max(gameScrollSpeedAt(ms), 0.0001);
    var size:Float = funkin.play.notes.Strumline.STRUMLINE_SIZE;
    var receptorOffset:Float = 0.275 * size;
    var distance:Float = downscroll ? (GAME_HEIGHT - size - Constants.STRUMLINE_Y_OFFSET - strumlineOffsetY + receptorOffset) + size : GAME_HEIGHT
      - (Constants.STRUMLINE_Y_OFFSET + receptorOffset);
    return visualMs + distance / pixelsPerMs;
  }

  /**
   * The last point at or before a position.
   */
  static function findScrollSpeedPoint(value:Float, byDistance:Bool):ScrollSpeedPoint
  {
    var points:Array<ScrollSpeedPoint> = scrollSpeedPoints;
    var low:Int = 0;
    var high:Int = points.length - 1;
    while (low < high)
    {
      var mid:Int = (low + high + 1) >> 1;
      var key:Float = byDistance ? points[mid].distance : points[mid].time;
      if (key <= value) low = mid;
      else
        high = mid - 1;
    }
    return points[low];
  }

  /**
   * How far the grid has scrolled at a song time, in milliseconds at 1x.
   */
  static function scrollSpeedDistance(ms:Float):Float
  {
    var point:ScrollSpeedPoint = findScrollSpeedPoint(ms, false);
    return point.distance + (ms - point.time) * point.speed;
  }

  /**
   * The song time at a scrolled distance. The opposite of `scrollSpeedDistance`.
   */
  static function scrollSpeedTime(distance:Float):Float
  {
    var point:ScrollSpeedPoint = findScrollSpeedPoint(distance, true);
    return point.time + (distance - point.distance) / point.speed;
  }
}

/**
 * One point in the constant scroll speed map. See `ChartEditorState.scrollSpeedPoints`.
 */
typedef ScrollSpeedPoint =
{
  var time:Float;
  var distance:Float;
  var speed:Float;
}
#end
