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
  static final CHARACTER_TARGETS = ["Position" => -1, "Player" => 0, "Opponent" => 1, "Girlfriend" => 2];

  static final EASE_TYPES = [
    'Linear' => 'linear',
    'Back In' => 'backIn',
    'Back Out' => 'backOut',
    'Back In/Out' => 'backInOut',
    'Circ In' => 'circIn',
    'Circ Out' => 'circOut',
    'Circ In/Out' => 'circInOut',
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
    'Instant (Ignores duration)' => 'INSTANT',
    'Classic (Ignores duration)' => 'CLASSIC'
  ];

  public function new()
  {
    super('FocusCamera');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    final playState = PlayState.instance;
    if (playState == null || playState.currentStage == null || playState.isMinimalMode) return;

    final stagePoint = data.getString('stagePoint') ?? 'NONE';
    final customPoints = playState.currentStage.customCameraPoints;

    var targetX:Float = data.getFloat('x') ?? 0.0;
    var targetY:Float = data.getFloat('y') ?? 0.0;
    var char = data.getInt('char') ?? cast data.value ?? 0;
    var duration = data.getFloat('duration') ?? 4.0;
    var ease = data.getString('ease') ?? 'CLASSIC';

    if (stagePoint != null && stagePoint != "NONE" && customPoints != null)
    {
      final point = customPoints.exists(stagePoint) ? customPoints.get(stagePoint) : null;
      if (point != null)
      {
        targetX += point.x;
        targetY += point.y;
      }
      else
        return;
    }
    else
    {
      final charPoint = getCharacterPoint(char);
      if (charPoint != null)
      {
        targetX += charPoint.x;
        targetY += charPoint.y;
      }
      else
        return;
    }

    applyCameraTween(targetX, targetY, duration, ease);
  }

  function getCharacterPoint(char:Int):Null<flixel.math.FlxPoint>
  {
    final currentStage = PlayState.instance.currentStage;
    return switch (char)
    {
      case -1: flixel.math.FlxPoint.get(); // Manual position
      case 0: currentStage.getBoyfriend()?.requiredCameraPos;
      case 1: currentStage.getDad()?.requiredCameraPos;
      case 2: currentStage.getGirlfriend()?.requiredCameraPos;
      default: null;
    }
  }

  function applyCameraTween(targetX:Float, targetY:Float, duration:Float, ease:String):Void
  {
    final playState = PlayState.instance;

    switch (ease)
    {
      case 'CLASSIC':
        playState.resetCamera(false, false, false);
        playState.cancelCameraFollowTween();
        playState.cameraFollowPoint.setPosition(targetX, targetY);

      case 'INSTANT':
        playState.tweenCameraToPosition(targetX, targetY, 0);

      default:
        final easeFunction = Reflect.field(FlxEase, ease);
        if (easeFunction == null) return;

        final durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        playState.tweenCameraToPosition(targetX, targetY, durSeconds, easeFunction);
    }
  }

  public override function getTitle():String
  {
    return 'Focus Camera';
  }

  private function getStageCameraPoints()
  {
    var cameraPoints:Map<String, String> = new Map();
    @:privateAccess
    var stage = funkin.data.stage.StageRegistry.instance.fetchEntry(funkin.ui.debug.charting.ChartEditorState.instance.currentSongStage);
    cameraPoints.set("NONE", "NONE");
    if (stage == null) return cameraPoints;
    if (funkin.ui.debug.charting.ChartEditorState.instance != null) for (point in stage?._data?.cameraPoints ?? [])
      cameraPoints.set(point.name, point.name);

    return cameraPoints;
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
        keys: CHARACTER_TARGETS
      },
      {
        name: "stagePoint",
        title: "Stage Point",
        defaultValue: "NONE",
        type: ENUM,
        keys: getStageCameraPoints()
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
        min: 0,
        step: 0.5,
        type: SongEventFieldType.FLOAT,
        units: 'steps'
      },
      {
        name: 'ease',
        title: 'Easing Type',
        defaultValue: 'CLASSIC',
        type: SongEventFieldType.ENUM,
        keys: EASE_TYPES
      }
    ]);
  }
}
