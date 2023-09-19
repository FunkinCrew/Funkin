package funkin.play.event;

// Data from the chart
import funkin.data.song.SongData;
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.play.event.SongEvent;
import funkin.data.event.SongEventData.SongEventSchema;
import funkin.data.event.SongEventData.SongEventFieldType;

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

    var posX:Null<Float> = data.getFloat('x');
    if (posX == null) posX = 0.0;
    var posY:Null<Float> = data.getFloat('y');
    if (posY == null) posY = 0.0;

    var char:Null<Int> = data.getInt('char');

    if (char == null) char = cast data.value;

    switch (char)
    {
      case -1: // Position
        trace('Focusing camera on static position.');
        var xTarget:Float = posX;
        var yTarget:Float = posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      case 0: // Boyfriend
        // Focus the camera on the player.
        if (PlayState.instance.currentStage.getBoyfriend() == null)
        {
          trace('No BF to focus on.');
          return;
        }
        trace('Focusing camera on player.');
        var xTarget:Float = PlayState.instance.currentStage.getBoyfriend().cameraFocusPoint.x + posX;
        var yTarget:Float = PlayState.instance.currentStage.getBoyfriend().cameraFocusPoint.y + posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      case 1: // Dad
        // Focus the camera on the dad.
        if (PlayState.instance.currentStage.getDad() == null)
        {
          trace('No dad to focus on.');
          return;
        }
        trace('Focusing camera on dad.');
        trace(PlayState.instance.currentStage.getDad());
        var xTarget:Float = PlayState.instance.currentStage.getDad().cameraFocusPoint.x + posX;
        var yTarget:Float = PlayState.instance.currentStage.getDad().cameraFocusPoint.y + posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      case 2: // Girlfriend
        // Focus the camera on the girlfriend.
        if (PlayState.instance.currentStage.getGirlfriend() == null)
        {
          trace('No GF to focus on.');
          return;
        }
        trace('Focusing camera on girlfriend.');
        var xTarget:Float = PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.x + posX;
        var yTarget:Float = PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.y + posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      default:
        trace('Unknown camera focus: ' + data);
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
    return [
      {
        name: "char",
        title: "Character",
        defaultValue: 0,
        type: SongEventFieldType.ENUM,
        keys: ["Position" => -1, "Boyfriend" => 0, "Dad" => 1, "Girlfriend" => 2]
      },
      {
        name: "x",
        title: "X Position",
        defaultValue: 0,
        step: 10.0,
        type: SongEventFieldType.FLOAT,
      },
      {
        name: "y",
        title: "Y Position",
        defaultValue: 0,
        step: 10.0,
        type: SongEventFieldType.FLOAT,
      }
    ];
  }
}
