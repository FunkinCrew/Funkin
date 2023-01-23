package funkin.play.event;

import funkin.play.event.SongEvent;
import funkin.play.song.SongData;

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

  public override function handleEvent(data:SongEventData)
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null)
      return;

    var posX = data.getFloat('x');
    if (posX == null)
      posX = 0.0;
    var posY = data.getFloat('y');
    if (posY == null)
      posY = 0.0;

    var char = data.getInt('char');

    if (char == null)
      char = cast data.value;

    switch (char)
    {
      case -1: // Position
        trace('Focusing camera on static position.');
        var xTarget = posX;
        var yTarget = posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      case 0: // Boyfriend
        // Focus the camera on the player.
        trace('Focusing camera on player.');
        var xTarget = PlayState.instance.currentStage.getBoyfriend().cameraFocusPoint.x + posX;
        var yTarget = PlayState.instance.currentStage.getBoyfriend().cameraFocusPoint.y + posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      case 1: // Dad
        // Focus the camera on the dad.
        trace('Focusing camera on dad.');
        var xTarget = PlayState.instance.currentStage.getDad().cameraFocusPoint.x + posX;
        var yTarget = PlayState.instance.currentStage.getDad().cameraFocusPoint.y + posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      case 2: // Girlfriend
        // Focus the camera on the girlfriend.
        trace('Focusing camera on girlfriend.');
        var xTarget = PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.x + posX;
        var yTarget = PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.y + posY;

        PlayState.instance.cameraFollowPoint.setPosition(xTarget, yTarget);
      default:
        trace('Unknown camera focus: ' + data);
    }
  }

  public override function getTitle():String
  {
    return "Focus Camera";
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
