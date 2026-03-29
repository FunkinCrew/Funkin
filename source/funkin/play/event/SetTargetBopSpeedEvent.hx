package funkin.play.event;

import flixel.FlxSprite;
import funkin.play.character.BaseCharacter;
import funkin.play.stage.Bopper;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class handles song events which changes dance speed of specific character or stage prop.
 */
class SetTargetBopSpeedSongEvent extends SongEvent
{
  public function new()
  {
    super('SetTargetBopSpeed');
  }

  static final DEFAULT_TARGET:String = 'boyfriend';

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    var targetName:Null<String> = data.getString('target');
    if (targetName == null) targetName = DEFAULT_TARGET;

    var rate = data.getFloat('rate');
    if (rate == null) rate = Constants.DEFAULT_PROP_RATE;

    var target:FlxSprite = null;

    switch (targetName)
    {
      case 'boyfriend' | 'bf' | 'player':
        trace('Set dance rate to $rate on boyfriend.');
        target = PlayState.instance.currentStage.getBoyfriend();
      case 'dad' | 'opponent':
        trace('Set dance rate to $rate on dad.');
        target = PlayState.instance.currentStage.getDad();
      case 'girlfriend' | 'gf':
        trace('Set dance rate to $rate on girlfriend.');
        target = PlayState.instance.currentStage.getGirlfriend();
      default:
        target = PlayState.instance.currentStage.getNamedProp(targetName);
        if (target == null) trace('Unknown target to set dance rate: $targetName');
        else
          trace('Set dance rate to $targetName from stage.');
    }

    if (target != null)
    {
      if (Std.isOfType(target, BaseCharacter))
      {
        var targetChar:BaseCharacter = cast target;
        targetChar.danceEvery = rate;
      }
      else if (Std.isOfType(target, Bopper))
      {
        var targetProp:Bopper = cast target;
        targetProp.danceEvery = rate;
      }
    }
    else
    {
      trace('Unknown SetTargetBopSpeed target: $targetName');
    }
  }

  public override function getTitle():String
  {
    return "Set Target Bop Speed";
  }

  /**
   * ```
   * {
   *   "target": STRING, // Name of character or prop to point to.
   *   "anim": STRING, // Name of animation to play.
   * }
   * ```
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([{
      name: 'target',
      title: 'Target',
      type: SongEventFieldType.STRING,
      defaultValue: DEFAULT_TARGET,
    }, {
      name: 'rate',
      title: 'Rate',
      defaultValue: Constants.DEFAULT_PROP_RATE,
      min: 0,
      step: 0.25,
      type: SongEventFieldType.FLOAT,
      units: 'beats/dance'
    }]);
  }
}
