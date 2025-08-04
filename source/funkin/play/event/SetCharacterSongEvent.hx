package funkin.play.event;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData;
import funkin.data.event.SongEventSchema;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.character.BaseCharacter;


/**
 * This class represents a handler for set character events.
 *
 * Example: Set the opponent to "Daddy Dearest":
 * ```
 * {
 *   'e': 'SetCharacter',
 * 	 "v": {
 * 	 	 "target": "dad",
 * 	 	 "character": "dad"
 *   }
 * }
 * ```
 */
class SetCharacterSongEvent extends SongEvent
{
  public function new()
  {
    super('SetCharacter');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;
    if (PlayState.instance.isMinimalMode) return;

    PlayState.instance.loadCharacter(data.value.character, data.value.target, true);
  }

  public override function getTitle():String
  {
    return 'Set Character';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'target',
        title: 'Target',
        defaultValue: CharacterType.DAD,
        type: SongEventFieldType.ENUM,
        keys: ["Player" => CharacterType.BF, "Opponent" => CharacterType.DAD, "Girlfriend" => CharacterType.GF]
      },
      {
        name: 'character',
        title: 'Character',
        defaultValue: 'dad',
        type: SongEventFieldType.ENUM,
        keys: generateCharacterList()
      }
    ]);
  }

  static function generateCharacterList():Map<String, String>
  {
    var characterIDs:Array<String> = CharacterDataParser.listCharacterIds();
    var characterMap:Map<String, String> = new Map<String, String>();

    for (character in characterIDs)
    {
      var characterData:Null<CharacterData> = CharacterDataParser.fetchCharacterData(character);
      characterMap.set(characterData.name, character);
    }
    return characterMap;
  }

}
