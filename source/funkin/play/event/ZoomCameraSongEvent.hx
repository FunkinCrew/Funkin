package funkin.play.event;

import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import funkin.ui.FullScreenScaleMode;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class handles song events which change the zoom level of the camera.
 *
 * Example: Zoom to 1.3x:
 * ```
 * {
 *   'e': 'ZoomCamera',
 *   'v': 1.3
 * }
 * ```
 */
class ZoomCameraSongEvent extends SongEvent
{
  public function new()
  {
    super('ZoomCamera', {
      processOldEvents: true
    });
  }

  public static final DEFAULT_ZOOM:Float = 1.0;
  public static final DEFAULT_WIDESCREEN_SCALE:Float = 0.0;
  public static final DEFAULT_DURATION:Float = 4.0;
  public static final DEFAULT_MODE:String = 'direct';

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    // Does nothing if we are minimal mode.
    if (PlayState.instance.isMinimalMode) return;

    var zoom:Float = data.getFloat('zoom') ?? DEFAULT_ZOOM;

    var widescreenScaleX:Float = data.getFloat('widescreenScaleX') ?? DEFAULT_WIDESCREEN_SCALE;
    var widescreenScaleY:Float = data.getFloat('widescreenScaleY') ?? DEFAULT_WIDESCREEN_SCALE;

    var scaledZoom:Float = zoom + (zoom * calculateScale(FullScreenScaleMode.wideScale, FlxPoint.get(widescreenScaleX, widescreenScaleY)));

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
        PlayState.instance.tweenCameraZoom(scaledZoom, 0, isDirectMode);
      default:
        var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        var easeFunctionName = '$ease$easeDir';
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, easeFunctionName);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $easeFunctionName');
          return;
        }

        PlayState.instance.tweenCameraZoom(scaledZoom, durSeconds, isDirectMode, easeFunction);
    }
  }

  function calculateScale(wideScale:FlxPoint, scale:FlxPoint)
  {
    return (wideScale.x - 1) * scale.x + (wideScale.y - 1) * scale.y;
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
    return new SongEventSchema([{
      name: 'zoom',
      title: 'Zoom Level',
      defaultValue: DEFAULT_ZOOM,
      min: 0,
      step: 0.05,
      type: SongEventFieldType.FLOAT,
      units: 'x'
    }, {
      name: 'duration',
      title: 'Duration',
      defaultValue: DEFAULT_DURATION,
      min: 0,
      step: 0.5,
      type: SongEventFieldType.FLOAT,
      units: 'steps'
    }, {
      name: 'ease',
      title: 'Easing Type',
      defaultValue: SongEvent.DEFAULT_EASE,
      type: SongEventFieldType.ENUM,
      keys: ['Linear' => 'linear', 'Instant (Ignores duration)' => 'INSTANT', 'Sine' => 'sine', 'Quad' => 'quad', 'Cube' => 'cube', 'Quart' => 'quart', 'Quint' => 'quint', 'Expo' => 'expo', 'Smooth Step' => 'smoothStep', 'Smoother Step' => 'smootherStep', 'Elastic' => 'elastic', 'Back' => 'back', 'Bounce' => 'bounce', 'Circ ' => 'circ',]
    }, {
      name: 'easeDir',
      title: 'Easing Direction',
      defaultValue: SongEvent.DEFAULT_EASE_DIR,
      type: SongEventFieldType.ENUM,
      keys: ['In' => 'In', 'Out' => 'Out', 'In/Out' => 'InOut']
    }, {
      name: 'advanced',
      title: 'Advanced',
      type: SongEventFieldType.FRAME,
      collapsible: true,
      children: [{
        name: 'mode',
        title: 'Mode',
        defaultValue: DEFAULT_MODE,
        type: SongEventFieldType.ENUM,
        keys: ['Stage zoom' => 'stage', 'Absolute zoom' => 'direct']
      }, {
        name: 'widescreenScaleX',
        title: 'Widescreen Scale X',
        defaultValue: DEFAULT_WIDESCREEN_SCALE,
        min: 0,
        max: 1,
        type: SongEventFieldType.FLOAT,
        units: 'x'
      }, {
        name: 'widescreenScaleY',
        title: 'Widescreen Scale Y',
        defaultValue: DEFAULT_WIDESCREEN_SCALE,
        min: 0,
        max: 1,
        type: SongEventFieldType.FLOAT,
        units: 'x'
      }]
    }]);
  }
}
