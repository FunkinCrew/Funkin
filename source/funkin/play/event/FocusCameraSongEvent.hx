package funkin.play.event;

import flixel.tweens.FlxEase;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class represents a handler for a type of song event.
 * It is used by the ScriptedSongEvent class to handle user-defined events.
 *
 * Example: Focus on Boyfriend:
 * ```
 * {
 *   "e": "FocusCamera",
 * 	 "v": {
 * 	 	 "char": 0,
 *   }
 * }
 * ```
 *
 * Example: Focus on 10px above Girlfriend:
 * ```
 * {
 *   "e": "FocusCamera",
 * 	 "v": {
 * 	   "char": 2,
 * 	   "y": -10,
 *   }
 * }
 * ```
 *
 * Example: Focus on (100, 100):
 * ```
 * {
 *   "e": "FocusCamera",
 *   "v": {
 *     "char": -1,
 *     "x": 100,
 *     "y": 100,
 *   }
 * }
 * ```
 */
class FocusCameraSongEvent extends SongEvent
{
  public function new()
  {
    super('FocusCamera');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    // Does nothing if we are minimal mode.
    if (PlayState.instance.isMinimalMode) return;

    var posX:Null<Float> = data.getFloat('x');
    if (posX == null) posX = 0.0;
    var posY:Null<Float> = data.getFloat('y');
    if (posY == null) posY = 0.0;

    var char:Null<Int> = data.getInt('char');

    if (char == null) char = cast data.value;

    var duration:Null<Float> = data.getFloat('duration');
    if (duration == null) duration = 4.0;
    var ease:Null<String> = data.getString('ease');
    if (ease == null) ease = 'CLASSIC';

    var currentStage = PlayState.instance.currentStage;

    // Get target position based on char.
    var targetX:Float = posX;
    var targetY:Float = posY;

    switch (char)
    {
      case -1: // Position ("focus" on origin)
        trace('Focusing camera on static position.');

      case 0: // Boyfriend (focus on player)
        if (currentStage.getBoyfriend() == null)
        {
          trace('No BF to focus on.');
          return;
        }
        trace('Focusing camera on player.');
        var bfPoint = currentStage.getBoyfriend().cameraFocusPoint;
        targetX += bfPoint.x;
        targetY += bfPoint.y;

      case 1: // Dad (focus on opponent)
        if (currentStage.getDad() == null)
        {
          trace('No dad to focus on.');
          return;
        }
        trace('Focusing camera on opponent.');
        var dadPoint = currentStage.getDad().cameraFocusPoint;
        targetX += dadPoint.x;
        targetY += dadPoint.y;

      case 2: // Girlfriend (focus on girlfriend)
        if (currentStage.getGirlfriend() == null)
        {
          trace('No GF to focus on.');
          return;
        }
        trace('Focusing camera on girlfriend.');
        var gfPoint = currentStage.getGirlfriend().cameraFocusPoint;
        targetX += gfPoint.x;
        targetY += gfPoint.y;

      default:
        trace('Unknown camera focus: ' + data);
    }

    // Apply tween based on ease.
    switch (ease)
    {
      case 'CLASSIC': // Old-school. No ease. Just set follow point.
        PlayState.instance.resetCamera(false, false, false);
        PlayState.instance.cancelCameraFollowTween();
        PlayState.instance.cameraFollowPoint.setPosition(targetX, targetY);
      case 'INSTANT': // Instant ease. Duration is automatically 0.
        PlayState.instance.tweenCameraToPosition(targetX, targetY, 0);
      default:
        var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $ease');
          return;
        }
        PlayState.instance.tweenCameraToPosition(targetX, targetY, durSeconds, easeFunction);
    }
  }

  public override function getTitle():String
  {
    return 'Focus Camera';
  }

  /**
   * ```
   * {
   *   "char": ENUM, // Which character to point to
   *   "x": FLOAT, // Optional x offset
   *   "y": FLOAT, // Optional y offset
   * }
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: "char",
        title: "Target",
        defaultValue: 0,
        type: SongEventFieldType.ENUM,
        keys: ["Position" => -1, "Player" => 0, "Opponent" => 1, "Girlfriend" => 2]
      },
      {
        name: "x",
        title: "X Position",
        defaultValue: 0,
        step: 10.0,
        type: SongEventFieldType.FLOAT,
        units: "px"
      },
      {
        name: "y",
        title: "Y Position",
        defaultValue: 0,
        step: 10.0,
        type: SongEventFieldType.FLOAT,
        units: "px"
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
          'Circ In/Out' => 'circInOut',
          'Instant (Ignores duration)' => 'INSTANT',
          'Classic (Ignores duration)' => 'CLASSIC'
        ]
      }
    ]);
  }
}
