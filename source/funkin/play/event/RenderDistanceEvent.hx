package funkin.play.event;

import funkin.data.event.SongEventSchema.SongEventFieldType;
import funkin.data.event.SongEventSchema;
import funkin.data.song.SongData.SongEventData;
import funkin.play.notes.Strumline;

/**
 * Sets the render distance on the strumline.
 *
 * Example: Only show notes 500ms ahead on the player strumline:
 * ```
 * {
 *   'e': 'RenderDistance',
 *   "v": {
 *      "distance": 500,
 *      "useDefault": false,
 *      "strumline": "player"
 *   }
 * }
 * ```
 */
class RenderDistanceEvent extends SongEvent
{
  public function new()
  {
    super('RenderDistance', {
      processOldEvents: true
    });
  }

  public static final DEFAULT_DISTANCE:Float = 1000;
  public static final DEFAULT_STRUMLINE:String = 'both';

  override public function handleEvent(data:SongEventData):Void
  {
    if (PlayState.instance == null) return;

    var distance:Float = Math.max(0, data.getFloat('distance') ?? DEFAULT_DISTANCE);
    var useDefault:Bool = data.getBool('useDefault') ?? false;

    for (strumline in getStrumlines(data.getString('strumline') ?? DEFAULT_STRUMLINE))
    {
      strumline.useCustomRenderDistance = !useDefault;
      strumline.customRenderDistanceMs = distance;
    }
  }

  static function getStrumlines(target:String):Array<Strumline>
  {
    var state:Null<PlayState> = PlayState.instance;
    if (state == null) return [];
    return switch (target)
    {
      case 'player': [state.playerStrumline];
      case 'opponent': [state.opponentStrumline];
      default: [state.playerStrumline, state.opponentStrumline];
    }
  }

  /**
   * Put both strumlines back on the screen based render distance, for restarts.
   */
  public static function resetStrumlines():Void
  {
    for (strumline in getStrumlines('both'))
    {
      if (strumline != null) strumline.useCustomRenderDistance = false;
    }
  }

  override public function getTitle():String
  {
    return 'Render Distance';
  }

  /**
   * ```
   * {
   *   'distance': FLOAT, // How far ahead notes spawn, in ms.
   *   'useDefault': BOOL, // Go back to the screen based distance.
   *   'strumline': ENUM, // Which strumline to change.
   * }
   * ```
   *
   * @return The `SongEventSchema`
   */
  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'distance',
        title: 'Distance',
        defaultValue: DEFAULT_DISTANCE,
        min: 0,
        step: 50,
        type: SongEventFieldType.FLOAT,
        units: 'ms'
      },
      {
        name: 'useDefault',
        title: 'Use Default',
        defaultValue: false,
        type: SongEventFieldType.BOOL
      },
      {
        name: 'strumline',
        title: 'Target Strumline',
        defaultValue: DEFAULT_STRUMLINE,
        type: SongEventFieldType.ENUM,
        keys: [
          'Both' => 'both',
          'Player' => 'player',
          'Opponent' => 'opponent'
        ]
      }
    ]);
  }
}
