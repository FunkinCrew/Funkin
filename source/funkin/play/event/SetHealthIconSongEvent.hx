package funkin.play.event;

import funkin.data.event.SongEventSchema;
import funkin.data.character.CharacterData.HealthIconData;
import funkin.data.song.SongData.SongEventData;

/**
 * This class handles song events which change the player's health icon, or the opponent's health icon.
 *
 * Example: Set the health icon of the opponent to "tankman-bloody":
 * ```
 * {
 *   'e': 'SetHealthIcon',
 * 	 "v": {
 * 	 	 "char": 1,
 *     "id": "tankman-bloody",
 *
 * // Optional params:
 *     "scale": 1.0,
 *     "flipX": false,
 *     "isPixel": false,
 *     "offsetX": 0.0,
 *     "offsetY": 0.0
 *   }
 * }
 * ```
 */
class SetHealthIconSongEvent extends SongEvent
{
  public function new()
  {
    super('SetHealthIcon', {
      processOldEvents: true
    });
  }

  static final DEFAULT_CHAR:Int = 0;
  static final DEFAULT_SCALE:Float = 1.0;
  static final DEFAULT_FLIPX:Bool = false;
  static final DEFAULT_ISPIXEL:Bool = false;

  static final DEFAULT_X_OFFSET:Float = 0.0;
  static final DEFAULT_Y_OFFSET:Float = 0.0;

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState.
    if (PlayState.instance == null) return;

    // Works even if we are minimal mode.
    // if (PlayState.instance.isMinimalMode) return;

    var offsets:Array<Float> = [data.value.offsetX ?? DEFAULT_X_OFFSET, data.value.offsetY ?? DEFAULT_Y_OFFSET];

    var healthIconData:HealthIconData = {
      id: data.value.id ?? Constants.DEFAULT_HEALTH_ICON,
      scale: data.value.scale ?? DEFAULT_SCALE,
      flipX: data.value.flipX ?? DEFAULT_FLIPX,
      isPixel: data.value.isPixel ?? DEFAULT_ISPIXEL,
      offsets: offsets,
    };

    switch (data?.value?.char ?? DEFAULT_CHAR)
    {
      case 0:
        if (PlayState.instance.iconP1 != null)
        {
          trace('Applying Player health icon via song event: ${healthIconData.id}');
          PlayState.instance.iconP1.configure(healthIconData);
        }
      case 1:
        if (PlayState.instance.iconP2 != null)
        {
          trace('Applying Opponent health icon via song event: ${healthIconData.id}');
          PlayState.instance.iconP2.configure(healthIconData);
        }
      default:
        trace(' WARNING '.warning() + ' SetHealthIconSongEvent: Unknown character index ' + data.value.char);
    }
  }

  public override function getTitle():String
  {
    return 'Set Health Icon';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([{
      name: 'char',
      title: 'Character',
      defaultValue: DEFAULT_CHAR,
      type: SongEventFieldType.ENUM,
      keys: ['Player' => 0, 'Opponent' => 1],
    }, {
      name: 'id',
      title: 'Health Icon ID',
      defaultValue: Constants.DEFAULT_HEALTH_ICON,
      type: SongEventFieldType.STRING,
    }, {
      name: 'scale',
      title: 'Scale',
      defaultValue: DEFAULT_SCALE,
      min: 0,
      type: SongEventFieldType.FLOAT,
    }, {
      name: 'flipX',
      title: 'Flip X?',
      defaultValue: DEFAULT_FLIPX,
      type: SongEventFieldType.BOOL,
    }, {
      name: 'isPixel',
      title: 'Is Pixel?',
      defaultValue: DEFAULT_ISPIXEL,
      type: SongEventFieldType.BOOL,
    }, {
      name: 'offsetX',
      title: 'X Offset',
      defaultValue: DEFAULT_X_OFFSET,
      type: SongEventFieldType.FLOAT,
    }, {
      name: 'offsetY',
      title: 'Y Offset',
      defaultValue: DEFAULT_Y_OFFSET,
      type: SongEventFieldType.FLOAT,
    }]);
  }
}
