package funkin.play.event;

import funkin.data.event.SongEventSchema;
import funkin.play.character.CharacterData.HealthIconData;
import funkin.data.song.SongData;
import funkin.data.song.SongData.SongEventData;

/**
 * This class represents a handler for scroll speed events.
 *
 * Example: Set the health icon of Boyfriend to "bf-pixel":
 * ```
 * {
 *   'e': 'SetHealthIcon',
 * 	 "v": {
 * 	 	 "char": 0,
 *     "id": "bf-pixel",
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
    super('SetHealthIcon');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState.
    if (PlayState.instance == null) return;

    // Works even if we are minimal mode.
    // if (PlayState.instance.isMinimalMode) return;

    var offsets:Array<Float> = [data.value.offsetX ?? 0.0, data.value.offsetY ?? 0.0];

    var healthIconData:HealthIconData =
      {
        id: data.value.id ?? "bf",
        scale: data.value.scale ?? 1.0,
        flipX: data.value.flipX ?? false,
        isPixel: data.value.isPixel ?? false,
        offsets: offsets,
      };

    switch (data?.value?.char ?? 0)
    {
      case 0:
        trace('Applying Player health icon via song event: ${healthIconData.id}');
        PlayState.instance.iconP1.configure(healthIconData);
      case 1:
        trace('Applying Opponent health icon via song event: ${healthIconData.id}');
        PlayState.instance.iconP2.configure(healthIconData);
      default:
        trace('[WARN] Unknown character index: ' + data.value.char);
    }
  }

  public override function getTitle():String
  {
    return 'Set Health Icon';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'char',
        title: 'Character',
        defaultValue: 0,
        type: SongEventFieldType.ENUM,
        keys: ['Player' => 0, 'Opponent' => 1],
      },
      {
        name: 'id',
        title: 'Health Icon ID',
        defaultValue: 'bf',
        type: SongEventFieldType.STRING,
      },
      {
        name: 'scale',
        title: 'Scale',
        defaultValue: 1.0,
        type: SongEventFieldType.FLOAT,
      },
      {
        name: 'flipX',
        title: 'Flip X?',
        defaultValue: false,
        type: SongEventFieldType.BOOL,
      },
      {
        name: 'isPixel',
        title: 'Is Pixel?',
        defaultValue: false,
        type: SongEventFieldType.BOOL,
      },
      {
        name: 'offsetX',
        title: 'X Offset',
        defaultValue: 0,
        type: SongEventFieldType.FLOAT,
      },
      {
        name: 'offsetY',
        title: 'Y Offset',
        defaultValue: 0,
        type: SongEventFieldType.FLOAT,
      }
    ]);
  }
}
