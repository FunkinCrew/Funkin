package funkin.play.event;

import flixel.tweens.FlxEase;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class represents a handler for camera zoom events.
 *
 * Example: Zoom to 1.3x:
 * ```
 * {
 *   'e': 'ZoomCamera',
 *   'v': 1.3
 * }
 * ```
 *
 * Example: Zoom to 1.3x
 * ```
 * {
 *   'e': 'FocusCamera',
 * 	 'v': {
 * 	   'char': 2,
 * 	   'y': -10,
 *   }
 * }
 * ```
 *
 * Example: Focus on (100, 100):
 * ```
 * {
 *   'e': 'FocusCamera',
 *   'v': {
 *     'char': -1,
 *     'x': 100,
 *     'y': 100,
 *   }
 * }
 * ```
 */
class ZoomCameraSongEvent extends SongEvent
{
  public function new()
  {
    super('ZoomCamera');
  }

  static final DEFAULT_ZOOM:Float = 1.0;
  static final DEFAULT_DURATION:Float = 4.0;
  static final DEFAULT_MODE:String = 'direct';

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    // Does nothing if we are minimal mode.
    if (PlayState.instance.isMinimalMode) return;

    var zoom:Float = data.getFloat('zoom') ?? DEFAULT_ZOOM;

    var duration:Float = data.getFloat('duration') ?? DEFAULT_DURATION;

    var mode:String = data.getString('mode') ?? DEFAULT_MODE;
    var isDirectMode:Bool = mode == 'direct';

    var ease:String = data.getString('ease') ?? SongEvent.DEFAULT_EASE;
    var easeDir:String = data.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;

    if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == "linear") easeDir = "";

    // If it's a string, check the value.
    switch (ease)
    {
      case 'INSTANT':
        PlayState.instance.tweenCameraZoom(zoom, 0, isDirectMode);
      default:
        var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease + easeDir);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $ease');
          return;
        }

        PlayState.instance.tweenCameraZoom(zoom, durSeconds, isDirectMode, easeFunction);
    }
  }

  public override function getTitle():String
  {
    return 'Zoom Camera';
  }

  /**
   * ```
   * {
   *   'zoom': FLOAT, // Target zoom level.
   *   'duration': FLOAT, // Duration in steps.
   *   'mode': ENUM, // Whether zoom is relative to the stage or absolute zoom.
   *   'ease': ENUM, // Easing function.
   *   'easeDir': ENUM, // Easing function direction (In, Out, InOut).
   * }
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'zoom',
        title: 'Zoom Level',
        defaultValue: 1.0,
        min: 0,
        step: 0.05,
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
        name: 'mode',
        title: 'Mode',
        defaultValue: 'stage',
        type: SongEventFieldType.ENUM,
        keys: ['Stage zoom' => 'stage', 'Absolute zoom' => 'direct']
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
      }
    ]);
  }
}
