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
@:nullSafety
class PlayAnimationSongEvent extends SongEvent
{
  public function new()
  {
    super('PlayAnimation');
  }

  public static final DEFAULT_TARGET:String = 'boyfriend';
  public static final DEFAULT_ANIM:String = 'idle';
  public static final DEFAULT_FORCE:Bool = false;

  override public function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    var anim:String = data.getString('anim') ?? DEFAULT_ANIM;
    var force:Bool = data.getBool('force') ?? DEFAULT_FORCE;
    var target:Null<FlxSprite> = getTarget(data);

    if (target != null)
    {
      if (Std.isOfType(target, BaseCharacter))
      {
        var targetChar:BaseCharacter = cast target;
        targetChar.tempVocals = force;
        targetChar.playAnimation(anim, force, force);
      }
      else
      {
        target.animation.play(anim, force);
      }
    }
    else
    {
      var targetName:String = data.getString('target') ?? DEFAULT_TARGET;
      trace('Unknown PlayAnimation target: $targetName');
    }
  }

  /**
   * Get the sprite which this PlayAnimation event will target.
   *
   * @param data The song data for the event.
   * @return The sprite to target, or `null` if the target is invalid.
   */
  public function getTarget(data:SongEventData):Null<FlxSprite>
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null || PlayState.instance.currentStage == null) return null;

    var targetName:String = data.getString('target') ?? DEFAULT_TARGET;

    switch (targetName)
    {
      case 'boyfriend' | 'bf' | 'player':
        return PlayState.instance.currentStage.getBoyfriend();
      case 'dad' | 'opponent':
        return PlayState.instance.currentStage.getDad();
      case 'girlfriend' | 'gf':
        return PlayState.instance.currentStage.getGirlfriend();
      default:
        return PlayState.instance.currentStage.getNamedProp(targetName);
    }
  }

  override public function getTitle():String
  {
    return 'Play Animation';
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
  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'target',
        title: 'Target',
        type: SongEventFieldType.STRING,
        defaultValue: DEFAULT_TARGET,
      },
      {
        name: 'anim',
        title: 'Animation',
        type: SongEventFieldType.STRING,
        defaultValue: DEFAULT_ANIM,
      },
      {
        name: 'force',
        title: 'Force',
        type: SongEventFieldType.BOOL,
        defaultValue: DEFAULT_FORCE
      }
    ]);
  }
}
