package funkin.play.event;

import flixel.FlxSprite;
import funkin.play.character.BaseCharacter;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

class PlayAnimationSongEvent extends SongEvent
{
  public function new()
  {
    super('PlayAnimation');
  }

  public override function handleEvent(data:SongEventData)
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    var targetName = data.getString('target');
    var anim = data.getString('anim');
    var force = data.getBool('force');
    if (force == null) force = false;

    var target:FlxSprite = null;

    switch (targetName)
    {
      case 'boyfriend' | 'bf' | 'player':
        trace('Playing animation $anim on boyfriend.');
        target = PlayState.instance.currentStage.getBoyfriend();
      case 'dad' | 'opponent':
        trace('Playing animation $anim on dad.');
        target = PlayState.instance.currentStage.getDad();
      case 'girlfriend' | 'gf':
        trace('Playing animation $anim on girlfriend.');
        target = PlayState.instance.currentStage.getGirlfriend();
      default:
        target = PlayState.instance.currentStage.getNamedProp(targetName);
        if (target == null) trace('Unknown animation target: $targetName');
        else
          trace('Fetched animation target $targetName from stage.');
    }

    if (target != null)
    {
      if (Std.isOfType(target, BaseCharacter))
      {
        var targetChar:BaseCharacter = cast target;
        targetChar.playAnimation(anim, force, force);
      }
      else
      {
        target.animation.play(anim, force);
      }
    }
  }

  public override function getTitle():String
  {
    return "Play Animation";
  }

  /**
   * ```
   * {
   *   "target": STRING, // Name of character or prop to point to.
   *   "anim": STRING, // Name of animation to play.
   *   "force": BOOL, // Whether to force the animation to play.
   * }
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'target',
        title: 'Target',
        type: SongEventFieldType.STRING,
        defaultValue: 'boyfriend',
      },
      {
        name: 'anim',
        title: 'Animation',
        type: SongEventFieldType.STRING,
        defaultValue: 'idle',
      },
      {
        name: 'force',
        title: 'Force',
        type: SongEventFieldType.BOOL,
        defaultValue: false
      }
    ]);
  }
}
