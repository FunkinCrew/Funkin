package funkin.data.freeplay.player;

import funkin.data.animation.AnimationData;

@:nullSafety
class PlayerData
{
  /**
   * The sematic version number of the player data JSON format.
   * Supports fancy comparisons like NPM does it's neat.
   */
  @:default(funkin.data.freeplay.player.PlayerRegistry.PLAYER_DATA_VERSION)
  public var version:String;

  /**
   * A readable name for this playable character.
   */
  public var name:String = 'Unknown';

  /**
   * The character IDs this character is associated with.
   * Only songs that use these characters will show up in Freeplay.
   */
  @:default([])
  public var ownedChars:Array<String> = [];

  /**
   * Whether to show songs with character IDs that aren't associated with any specific character.
   */
  @:optional
  @:default(false)
  public var showUnownedChars:Bool = false;

  /**
   * Data for displaying this character in the Freeplay menu.
   * If null, display no DJ.
   */
  public var freeplayDJ:Null<PlayerFreeplayDJData> = null;

  /**
   * Whether this character is unlocked by default.
   * Use a ScriptedPlayableCharacter to add custom logic.
   */
  @:optional
  @:default(true)
  public var unlocked:Bool = true;

  public function new()
  {
    this.version = PlayerRegistry.PLAYER_DATA_VERSION;
  }

  /**
   * Convert this StageData into a JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var writer = new json2object.JsonWriter<PlayerData>();
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.version = PlayerRegistry.PLAYER_DATA_VERSION;
  }
}

class PlayerFreeplayDJData
{
  var assetPath:String;
  var animations:Array<AnimationData>;

  @:jignored
  var animationMap:Map<String, AnimationData>;

  @:optional
  var cartoon:Null<PlayerFreeplayDJCartoonData>;

  public function new()
  {
    animationMap = new Map();
  }

  function mapAnimations()
  {
    if (animationMap == null) animationMap = new Map();

    animationMap.clear();
    for (anim in animations)
    {
      animationMap.set(anim.name, anim);
    }
  }

  public function getAtlasPath():String
  {
    return Paths.animateAtlas(assetPath);
  }

  public function getAnimationPrefix(name:String):Null<String>
  {
    if (animationMap.size() == 0) mapAnimations();

    var anim = animationMap.get(name);
    if (anim == null) return null;
    return anim.prefix;
  }

  public function getAnimationOffsets(name:String):Null<Array<Float>>
  {
    if (animationMap.size() == 0) mapAnimations();

    var anim = animationMap.get(name);
    if (anim == null) return null;
    return anim.offsets;
  }

  // TODO: These should really be frame labels, ehe.

  public function getCartoonSoundClickFrame():Int
  {
    return cartoon?.soundClickFrame ?? 80;
  }

  public function getCartoonSoundCartoonFrame():Int
  {
    return cartoon?.soundCartoonFrame ?? 85;
  }

  public function getCartoonLoopBlinkFrame():Int
  {
    return cartoon?.loopBlinkFrame ?? 112;
  }

  public function getCartoonLoopFrame():Int
  {
    return cartoon?.loopFrame ?? 166;
  }

  public function getCartoonChannelChangeFrame():Int
  {
    return cartoon?.channelChangeFrame ?? 60;
  }
}

typedef PlayerFreeplayDJCartoonData =
{
  var soundClickFrame:Int;
  var soundCartoonFrame:Int;
  var loopBlinkFrame:Int;
  var loopFrame:Int;
  var channelChangeFrame:Int;
}
