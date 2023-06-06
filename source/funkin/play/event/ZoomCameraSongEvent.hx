package funkin.play.event;

import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import funkin.play.event.SongEvent;
import funkin.play.song.SongData;
import funkin.play.event.SongEventData;
import funkin.play.event.SongEventData.SongEventFieldType;

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

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null) return;

    var zoom:Null<Float> = data.getFloat('zoom');
    if (zoom == null) zoom = 1.0;
    var duration:Null<Float> = data.getFloat('duration');
    if (duration == null) duration = 4.0;

    var ease:Null<String> = data.getString('ease');
    if (ease == null) ease = 'linear';

    // If it's a string, check the value.
    switch (ease)
    {
      case 'INSTANT':
        // Set the zoom. Use defaultCameraZoom to prevent breaking camera bops.
        PlayState.instance.defaultCameraZoom = zoom * FlxCamera.defaultZoom;
      default:
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $ease');
          return;
        }

        FlxTween.tween(PlayState.instance, {defaultCameraZoom: zoom * FlxCamera.defaultZoom}, (Conductor.stepCrochet * duration / 1000), {ease: easeFunction});
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
   *   'duration': FLOAT, // Optional duration in steps
   *   'ease': ENUM, // Optional easing function
   * }
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return [
      {
        name: 'zoom',
        title: 'Zoom Level',
        defaultValue: 1.0,
        step: 0.1,
        type: SongEventFieldType.FLOAT
      },
      {
        name: 'duration',
        title: 'Duration (in steps)',
        defaultValue: 4.0,
        step: 0.5,
        type: SongEventFieldType.FLOAT,
      },
      {
        name: 'ease',
        title: 'Easing Type',
        defaultValue: 'linear',
        type: SongEventFieldType.ENUM,
        keys: [
          'Linear' => 'linear',
          'Instant' => 'INSTANT',
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
          'Smooth Step In' => 'smoothStepIn',
          'Smooth Step Out' => 'smoothStepOut',
          'Smooth Step In/Out' => 'smoothStepInOut',
          'Sine In' => 'sineIn',
          'Sine Out' => 'sineOut',
          'Sine In/Out' => 'sineInOut',
          'Elastic In' => 'elasticIn',
          'Elastic Out' => 'elasticOut',
          'Elastic In/Out' => 'elasticInOut',
        ]
      }
    ];
  }
}
