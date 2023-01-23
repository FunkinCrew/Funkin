package funkin.play.event;

import flixel.FlxSprite;
import funkin.play.character.BaseCharacter;
import funkin.play.event.SongEvent;
import funkin.play.song.SongData;

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
      case 'boyfriend':
        trace('Playing animation $anim on boyfriend.');
        target = PlayState.instance.currentStage.getBoyfriend();
      case 'bf':
        trace('Playing animation $anim on boyfriend.');
        target = PlayState.instance.currentStage.getBoyfriend();
      case 'player':
        trace('Playing animation $anim on boyfriend.');
        target = PlayState.instance.currentStage.getBoyfriend();
      case 'dad':
        trace('Playing animation $anim on dad.');
        target = PlayState.instance.currentStage.getDad();
      case 'opponent':
        trace('Playing animation $anim on dad.');
        target = PlayState.instance.currentStage.getDad();
      case 'girlfriend':
        trace('Playing animation $anim on girlfriend.');
        target = PlayState.instance.currentStage.getGirlfriend();
      case 'gf':
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
    return [
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
    ];
  }
}
