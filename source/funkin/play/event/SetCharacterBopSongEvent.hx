package funkin.play.event;

import flixel.FlxSprite;
import funkin.play.character.BaseCharacter;
import funkin.play.stage.Bopper;
// Data from the chart
import funkin.data.event.SongEventSchema;
// Data from the event schema
import funkin.data.song.SongData;
import funkin.data.song.SongData.SongEventData;

/**
 * This class represents a handler for character bop.
 *
 * Example: Make gf dance SLOWLY:
 * ```
 * {
 *   'e': 'SetCharacterBop',
 * 	 "v": {
 * 	 	 "char": 0,
 *     "rate": "2",
 *   }
 * }
 * ```
 */
class SetCharacterBopSongEvent extends SongEvent
{
  public function new()
  {
    super('SetCharacterbop');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    // Does nothing if we are minimal mode.
    if (PlayState.instance.isMinimalMode) return;

    var char:Null<Int> = data.getInt('char');

    if (char == null) char = cast data.value;

    var rate:Null<Float> = data.getInt('rate');
    if (rate == null) rate = 1.0;

    var characterBopChange:Bopper = null;

    switch (char)
    {
      case 0:
        trace('Applying Player Bop via song event.');
        characterBopChange = PlayState.instance.currentStage.getBoyfriend();
        characterBopChange.danceEvery = rate;
      case 1:
        trace('Applying Opponent Bop via song event.');
        characterBopChange = PlayState.instance.currentStage.getOpponent();
        characterBopChange.danceEvery = rate;
      case 2:
        trace('Applying Girlfriend Bop via song event.');
        characterBopChange = PlayState.instance.currentStage.getGirlfriend();
        characterBopChange.danceEvery = rate;
      default:
        trace('[WARN] Character for Bop apply was not found.');
    }
  }

  public override function getTitle():String
  {
    return 'Set Character Speed';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'char',
        title: 'Character',
        defaultValue: 0,
        type: SongEventFieldType.ENUM,
        keys: ['Player' => 0, 'Opponent' => 1, 'Girlfriend' => 2],
      },
      {
        name: 'rate',
        title: 'Rate',
        defaultValue: 1,
        step: 1,
        type: SongEventFieldType.INTEGER,
        units: 'beats/bop',
        min: 0
      }
    ]);
  }
}
