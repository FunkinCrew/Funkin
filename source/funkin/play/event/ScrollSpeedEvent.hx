package funkin.play.event;

import flixel.tweens.FlxEase;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class represents a handler for scroll speed events.
 *
 * Example: Scroll speed change of both strums from 1x to 1.3x:
 * ```
 * {
 *   'e': 'ScrollSpeed',
 *   "v": {
 *      "scroll": "1.3",
 *      "duration": "4",
 *      "ease": "linear",
 *      "strumline": "both",
 *      "absolute": false
 *    }
 * }
 * ```
 */
class ScrollSpeedEvent extends SongEvent
{
  public function new()
  {
    super('ScrollSpeed');
  }

  static final DEFAULT_SCROLL:Float = 1;
  static final DEFAULT_DURATION:Float = 4.0;
  static final DEFAULT_ABSOLUTE:Bool = false;
  static final DEFAULT_STRUMLINE:String = 'both'; // my special little trick

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState.
    if (PlayState.instance == null) return;

    var scroll:Float = data.getFloat('scroll') ?? DEFAULT_SCROLL;

    var duration:Float = data.getFloat('duration') ?? DEFAULT_DURATION;

    var ease:String = data.getString('ease') ?? SongEvent.DEFAULT_EASE;
    var easeDir:String = data.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;

    if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == "linear") easeDir = "";

    var strumline:String = data.getString('strumline') ?? DEFAULT_STRUMLINE;

    var absolute:Bool = data.getBool('absolute') ?? DEFAULT_ABSOLUTE;

    var strumlineNames:Array<String> = [];

    if (!absolute)
    {
      // If absolute is set to false, do the awesome multiplicative thing
      scroll = scroll * (PlayState.instance?.currentChart?.scrollSpeed ?? 1.0);
    }

    switch (strumline)
    {
      case 'both':
        strumlineNames = ['playerStrumline', 'opponentStrumline'];
      default:
        strumlineNames = [strumline + 'Strumline'];
    }
    // If it's a string, check the value.
    switch (ease)
    {
      case 'INSTANT':
        PlayState.instance.tweenScrollSpeed(scroll, 0, null, strumlineNames);
      default:
        var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease + easeDir);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $ease');
          return;
        }

        PlayState.instance.tweenScrollSpeed(scroll, durSeconds, easeFunction, strumlineNames);
    }
  }

  public override function getTitle():String
  {
    return 'Scroll Speed';
  }

  /**
   * ```
   * {
   *   'scroll': FLOAT, // Target scroll level.
   *   'duration': FLOAT, // Duration in steps.
   *   'ease': ENUM, // Easing function.
   *   'easeDir': ENUM, // Easing function direction (In, Out, InOut).
   *   'strumline': ENUM, // Which strumline to change
   *   'absolute': BOOL, // True to set the scroll speed to the target level, false to set the scroll speed to (target level x base scroll speed)
   * }
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'scroll',
        title: 'Target Value',
        defaultValue: 1.0,
        min: 0.1,
        step: 0.1,
        type: SongEventFieldType.FLOAT,
        units: 'x'
      },
      {
        name: 'duration',
        title: 'Duration',
        defaultValue: 4.0,
        min: 0,
        step: 0.5,
        type: SongEventFieldType.FLOAT,
        units: 'steps'
      },
      {
        name: 'ease',
        title: 'Easing Type',
        defaultValue: 'linear',
        type: SongEventFieldType.ENUM,
        keys: [
          'Linear' => 'linear',
          'Instant (Ignores duration)' => 'INSTANT',
          'Sine' => 'sine',
          'Quad' => 'quad',
          'Cube' => 'cube',
          'Quart' => 'quart',
          'Quint' => 'quint',
          'Expo' => 'expo',
          'Smooth Step' => 'smoothStep',
          'Smoother Step' => 'smootherStep',
          'Elastic' => 'elastic',
          'Back' => 'back',
          'Bounce' => 'bounce',
          'Circ ' => 'circ',
        ]
      },
      {
        name: 'easeDir',
        title: 'Easing Direction',
        defaultValue: 'In',
        type: SongEventFieldType.ENUM,
        keys: ['In' => 'In', 'Out' => 'Out', 'In/Out' => 'InOut']
      },
      {
        name: 'strumline',
        title: 'Target Strumline',
        defaultValue: 'both',
        type: SongEventFieldType.ENUM,
        keys: ['Both' => 'both', 'Player' => 'player', 'Opponent' => 'opponent']
      },
      {
        name: 'absolute',
        title: 'Absolute',
        defaultValue: false,
        type: SongEventFieldType.BOOL,
      }
    ]);
  }
}
