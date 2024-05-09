package funkin.play.event;

import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
// Data from the chart
import funkin.data.song.SongData;
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.play.event.SongEvent;
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class represents a handler for scroll speed events.
 *
 * Example: Scroll speed change of both strums from 1x to 1.3x:
 * ```
 * {
 *   'e': 'AdditiveScrollSpeed',
 *   "v": {
 *      "scroll": "0.3",
 *      "duration": "4",
 *      "ease": "linear"
 *    }
 * }
 * ```
 */
class AdditiveScrollSpeedEvent extends SongEvent
{
  public function new()
  {
    super('AdditiveScrollSpeed');
  }

  static final DEFAULT_SCROLL:Float = 0;
  static final DEFAULT_DURATION:Float = 4.0;
  static final DEFAULT_EASE:String = 'linear';

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    var scroll:Float = data.getFloat('scroll') ?? DEFAULT_SCROLL;

    var duration:Float = data.getFloat('duration') ?? DEFAULT_DURATION;

    var ease:String = data.getString('ease') ?? DEFAULT_EASE;

    // If it's a string, check the value.
    switch (ease)
    {
      case 'INSTANT':
        PlayState.instance.tweenAdditiveScrollSpeed(scroll, 0);
      default:
        var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $ease');
          return;
        }

        PlayState.instance.tweenAdditiveScrollSpeed(scroll, durSeconds, easeFunction);
    }
  }

  public override function getTitle():String
  {
    return 'Additive Scroll Speed';
  }

  /**
   * ```
   * {
   *   'scroll': FLOAT, // Target additive scroll level.
   *   'duration': FLOAT, // Duration in steps.
   *   'ease': ENUM, // Easing function.
   * }
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'scroll',
        title: 'Additive Scroll Amount',
        defaultValue: 0.0,
        step: 0.1,
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
          'Elastic In' => 'elasticIn',
          'Elastic Out' => 'elasticOut',
          'Elastic In/Out' => 'elasticInOut'
        ]
      }
    ]);
  }
}
