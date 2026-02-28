package funkin.play.event;

import flixel.FlxSprite;
import funkin.play.character.BaseCharacter;
// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class handles song events which force a specific character or stage prop to play an animation.
 */
class PlayAnimationSongEvent extends SongEvent
{
  public function new()
  {
    super('PlayAnimation');
  }

  static final DEFAULT_TARGET:String = 'boyfriend';
  static final DEFAULT_ANIM:String = 'idle';
  static final DEFAULT_FORCE:Bool = false;

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    var targetName:Null<String> = data.getString('target');
    if (targetName == null) targetName = DEFAULT_TARGET;

    var anim = data.getString('anim');
    if (anim == null) anim = DEFAULT_ANIM;

    var force = data.getBool('force');
    if (force == null) force = DEFAULT_FORCE;

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
    else
    {
      trace('Unknown PlayAnimation target: $targetName');
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
    return new SongEventSchema([{
      name: 'target',
      title: 'Target',
      type: SongEventFieldType.STRING,
      defaultValue: DEFAULT_TARGET,
    }, {
      name: 'anim',
      title: 'Animation',
      type: SongEventFieldType.STRING,
      defaultValue: DEFAULT_ANIM,
    }, {
      name: 'force',
      title: 'Force',
      type: SongEventFieldType.BOOL,
      defaultValue: DEFAULT_FORCE
    }]);
  }
}
