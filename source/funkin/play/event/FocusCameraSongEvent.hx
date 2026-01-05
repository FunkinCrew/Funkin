package funkin.play.event;

import flixel.tweens.FlxEase;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class handles song events which change the camera focus.
 * This lets you center the camera on a character, on a stage prop, or a specific position on the screen,
 * as well as apply relative offsets, and even determine the speed and manner with which
 * the camera moves into place.
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
    super('FocusCamera',
      {
        processOldEvents: true
      });
  }

  static final DEFAULT_X_POSITION:Float = 0.0;
  static final DEFAULT_Y_POSITION:Float = 0.0;
  static final DEFAULT_DURATION:Float = 4.0;
  static final DEFAULT_CAMERA_EASE:String = 'CLASSIC';
  static final DEFAULT_TARGET:Int = 0; // Boyfriend

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    // Does nothing if we are minimal mode.
    if (PlayState.instance.isMinimalMode) return;

    var posX:Null<Float> = data.getFloat('x');
    if (posX == null) posX = DEFAULT_X_POSITION;
    var posY:Null<Float> = data.getFloat('y');
    if (posY == null) posY = DEFAULT_Y_POSITION;

    var char:Null<Int> = data.getInt('char');

    if (char == null) char = cast data.value;
    if (char == null) char = DEFAULT_TARGET;

    var duration:Null<Float> = data.getFloat('duration');
    if (duration == null) duration = DEFAULT_DURATION;
    var ease:Null<String> = data.getString('ease');
    if (ease == null) ease = DEFAULT_CAMERA_EASE; // No linear in defaults lol

    var easeDir:String = data.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;
    if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == "linear") easeDir = "";

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
        var easeFunctionName = '$ease$easeDir';
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, easeFunctionName);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $easeFunctionName');
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
        defaultValue: DEFAULT_TARGET,
        type: SongEventFieldType.ENUM,
        keys: ["Position" => -1, "Player" => 0, "Opponent" => 1, "Girlfriend" => 2]
      },
      {
        name: "x",
        title: "X Position",
        defaultValue: DEFAULT_X_POSITION,
        step: 10.0,
        type: SongEventFieldType.FLOAT,
        units: "px"
      },
      {
        name: "y",
        title: "Y Position",
        defaultValue: DEFAULT_Y_POSITION,
        step: 10.0,
        type: SongEventFieldType.FLOAT,
        units: "px"
      },
      {
        name: 'duration',
        title: 'Duration',
        defaultValue: DEFAULT_DURATION,
        min: 0,
        step: 0.5,
        type: SongEventFieldType.FLOAT,
        units: 'steps'
      },
      {
        name: 'ease',
        title: 'Easing Type',
        defaultValue: DEFAULT_CAMERA_EASE,
        type: SongEventFieldType.ENUM,
        keys: [
          'Linear' => 'linear',
          'Instant (Ignores duration)' => 'INSTANT',
          'Classic (Ignores duration)' => 'CLASSIC',
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
        defaultValue: SongEvent.DEFAULT_EASE_DIR,
        type: SongEventFieldType.ENUM,
        keys: ['In' => 'In', 'Out' => 'Out', 'In/Out' => 'InOut']
      }
    ]);
  }
}
