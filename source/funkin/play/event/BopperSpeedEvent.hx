package funkin.play.event;

// Data from the chart
import funkin.play.character.BaseCharacter;
import funkin.data.song.SongData;
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.play.event.SongEvent;
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

import funkin.play.stage.Bopper;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class BopperSpeedEvent extends SongEvent
{
  public function new()
  {
    super("BopperSpeed");
  }

  static final DEFAULT_DANCE_EVERY:Int = 1;

  public override function handleEvent(data:SongEventData):Void
  {
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    var bopperName:String = data.getString('bopper');

    var speed:Int = data.getInt('danceEvery') ?? DEFAULT_DANCE_EVERY;

    var bopperProp:FlxSprite = null;

    switch(bopperName)
    {
      case 'boyfriend' | 'bf' | 'player':
        bopperProp = PlayState.instance.currentStage.getBoyfriend();
      case 'dad' | 'opponent':
        bopperProp = PlayState.instance.currentStage.getDad();
      case 'girlfriend' | 'gf':
        bopperProp = PlayState.instance.currentStage.getGirlfriend();
      default:
        bopperProp = PlayState.instance.currentStage.getNamedProp(bopperName);
    }

    if(bopperProp != null) {
      if ((Std.isOfType(bopperProp, Bopper)) || (Std.isOfType(bopperProp, BaseCharacter)))
      {
        var bopper = cast(bopperProp, Bopper);
        trace('Setting $bopperName speed to $speed.');
        bopper.danceEvery = speed;
      }
    }
  }

  public override function getTitle():String
  {
    return 'Set Bopper Speed';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'bopper',
        title: 'Target (ID)',
        type: SongEventFieldType.STRING,
        defaultValue: 'girlfriend',
      },
      {
        name: 'danceEvery',
        title: 'Dance Every Value',
        defaultValue: 1,
        step: 1,
        min: 1,
        type: SongEventFieldType.INTEGER,
      }
    ]);
  }
}
