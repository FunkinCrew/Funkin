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
  static final DEFAULT_EASE:String = 'linear';

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

    var ease:String = data.getString('ease') ?? DEFAULT_EASE;

    // If it's a string, check the value.
    switch (ease)
    {
      case 'INSTANT':
        PlayState.instance.tweenCameraZoom(zoom, 0, isDirectMode);
      default:
        var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease);
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
        step: 0.05,
        type: SongEventFieldType.FLOAT,
        units: 'x'
      },
      {
        name: 'duration',
        title: 'Duration',
        defaultValue: 4.0,
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
          'Instant' => 'INSTANT',
          'Sine In' => 'sineIn',
          'Sine Out' => 'sineOut',
          'Sine In/Out' => 'sineInOut',
          'Quad In' => 'quadIn',
          'Quad Out' => 'quadOut',
          'Quad In/Out' => 'quadInOut',
          'Cube In' => 'cubeIn',
          'Cube Out' => 'cubeOut',
          'Cube In/Out' => 'cubeInOut',
          'Quart In' => 'quartIn',
          'Quart Out' => 'quartOut',
          'Quart In/Out' => 'quartInOut',
          'Quint In' => 'quintIn',
          'Quint Out' => 'quintOut',
          'Quint In/Out' => 'quintInOut',
          'Expo In' => 'expoIn',
          'Expo Out' => 'expoOut',
          'Expo In/Out' => 'expoInOut',
          'Smooth Step In' => 'smoothStepIn',
          'Smooth Step Out' => 'smoothStepOut',
          'Smooth Step In/Out' => 'smoothStepInOut',
          'Smoother Step In' => 'smootherStepIn',
          'Smoother Step Out' => 'smootherStepOut',
          'Smoother Step In/Out' => 'smootherStepInOut',
          'Elastic In' => 'elasticIn',
          'Elastic Out' => 'elasticOut',
          'Elastic In/Out' => 'elasticInOut',
          'Back In' => 'backIn',
          'Back Out' => 'backOut',
          'Back In/Out' => 'backInOut',
          'Bounce In' => 'bounceIn',
          'Bounce Out' => 'bounceOut',
          'Bounce In/Out' => 'bounceInOut',
          'Circ In' => 'circIn',
          'Circ Out' => 'circOut',
          'Circ In/Out' => 'circInOut'
        ]
      }
    ]);
  }
}
