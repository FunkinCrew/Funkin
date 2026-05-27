package funkin.play.event;

import funkin.data.event.SongEventSchema;
import funkin.data.song.SongData.SongEventData;
import funkin.data.character.CharacterDataParser;

/**
 * This class handles song events that switches the character
 */
class SetCharacterSongEvent extends SongEvent
{
  public function new()
  {
    super('SetCharacter', {
	  processOldEvents: true
	});
  }

   static final DEFAULT_CHAR:String = 'bf';
   static final DEFAULT_NEWCHAR:String = 'dad';
   static final DEFAULT_X:Float = 0;
   static final DEFAULT_Y:Float = 0;

  override public function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState.
    if (PlayState.instance == null) return;

    //Does nothing in minimal mode.
    if (PlayState.instance.isMinimalMode) return;

	var char = data.getString('char') ?? DEFAULT_CHAR;
	var newChar = data.getString('newchar') ?? DEFAULT_NEWCHAR;
	var offsetX = data.getFloat('x') ?? DEFAULT_X;
	var offsetY = data.getFloat('y') ?? DEFAULT_Y;
	  
    PlayState.instance.changeCharacter(char, newChar, offsetX, offsetY);
   }

  override public function getTitle():String
  {
    return 'Set Character';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'char',
        title: 'Character',
        defaultValue: DEFAULT_CHAR,
        type: SongEventFieldType.ENUM,
        keys: ['Boyfriend' => 'bf', 'Dad' => 'dad', 'Girlfriend' => 'gf'],
      },
      {
        name: 'newchar',
        title: 'New Character',
        defaultValue: DEFAULT_NEWCHAR,
        type: SongEventFieldType.ENUM,
        keys: generateCharList(),
      },
	  {
		name: 'x',
	    title: 'Offset X',
		defaultValue: DEFAULT_X,
		step: 10.0,
		type: SongEventFieldType.FLOAT,
		units: 'x'
	  },
	  {
		name: 'y',
	    title: 'Offset Y',
		defaultValue: DEFAULT_Y,
		step: 10.0,
		type: SongEventFieldType.FLOAT,
		units: 'x'
		}
    ]);
  }

/**
 * List of all Characters.
 */
  function generateCharList()
  {
      var charIDs:Array<String> = CharacterDataParser.listCharacterIds();
      var charMap:Map<String, String> = new Map();

      for (charID in charIDs)
      {
         var charData:CharacterData = CharacterDataParser.fetchCharacterData(charID);
         charMap.set(charData.name, charID);
      }
      return charMap;
  }
}
