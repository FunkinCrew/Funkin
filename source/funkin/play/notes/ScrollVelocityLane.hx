package funkin.play.notes;

import funkin.data.song.SongData.SongEventData;

/**
 * A lane of notes with a specific column and strumline, tracking their scroll velocity.
 **/
@:nullSafety
class ScrollVelocityLane
{
  /**
   * Warp events, which change how fast the notes move toward the strums.
   */
  public var warp(default, null):ScrollVelocityTimeline;

  /**
   * Track events, which change how fast the notes move toward the strums.
   * This changes the spacing of the notes (but still allows for stops, reversing, etc).
   */
  public var track(default, null):ScrollVelocityTimeline;

  /**
   * The song time the notes are drawn around, from the normal events.
   */
  public var visualTime(default, null):Float = 0;

  var songTime:Float = 0;
  var trackNow:Float = 0;
  var lagStretchStart:Float = -1;
  var lagPixels:Float = 0;
  var lagPrevious:Float = 0;

  /**
   * @param events The chart's events.
   * @param strumline `player` or `opponent`.
   * @param column The column of the events to take, on top of the ones for every column.
   * @param conductor Used for the length of a step. Defaults to `Conductor.instance`.
   */
  public function new(events:Array<SongEventData>, strumline:String, column:Int, ?conductor:Conductor)
  {
    warp = new ScrollVelocityTimeline(events, strumline, conductor, false, column);
    track = new ScrollVelocityTimeline(events, strumline, conductor, true, column);
  }

  /**
   * Build a lane for each column of a strumline.
   * @param mirrored If true, the columns are reversed.
   */
  public static function build(events:Array<SongEventData>, strumline:String, mirrored:Bool = false, ?conductor:Conductor):Array<ScrollVelocityLane>
  {
    return [
      for (i in 0...Strumline.KEY_COUNT)
        new ScrollVelocityLane(events, strumline, mirrored ? Strumline.KEY_COUNT - 1 - i : i, conductor)
    ];
  }

  /**
   * Update the lane's state for a song time.
   * @param time The real song time.
   * @param scrollSpeed The scroll speed now.
   */
  public function update(time:Float, scrollSpeed:Float):Void
  {
    var stretchStart:Float = warp.stretchStartAt(time);
    var lag:Float = time - warp.visualTime(time);
    if (stretchStart != lagStretchStart || time < songTime)
    {
      lagStretchStart = stretchStart;
      lagPixels = lag * scrollSpeed;
    }
    else
    {
      lagPixels = ScrollVelocityTimeline.stepLag(lagPixels, lagPrevious, lag, scrollSpeed);
    }
    lagPrevious = lag;
    songTime = time;
    visualTime = (stretchStart < 0) ? time - lag : ScrollVelocityTimeline.lagToVisual(time, lagPixels, lag, scrollSpeed);
    trackNow = track.position(time);
  }

  /**
   * The distance from the note's position to the receptor, in pixels.
   */
  public function distance(strumTime:Float):Float
  {
    return (track.position(strumTime) - trackNow) + (songTime - visualTime);
  }

  /**
   * How much longer or shorter a hold is drawn than its length in time.
   */
  public function lengthScale(strumTime:Float, length:Float):Float
  {
    if (!track.hasEvents || length <= 0) return 1;
    return Math.max(0, (track.position(strumTime + length) - track.position(strumTime)) / length);
  }

  /**
   * The time at which a note should be spawned, given the render distance.
   */
  public function spawnTime(renderDistance:Float):Float
  {
    var ahead:Float = Math.max(songTime, visualTime) + renderDistance;
    if (!track.hasEvents) return ahead;
    return Math.max(ahead, track.reach(songTime, renderDistance + Math.max(0, visualTime - songTime)));
  }
}
