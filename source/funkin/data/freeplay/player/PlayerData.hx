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
  @:optional
  public var freeplayDJ:Null<PlayerFreeplayDJData> = null;

  public var results:Null<PlayerResultsData> = null;

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

  @:optional
  @:default("BOYFRIEND")
  var text1:String;

  @:optional
  @:default("HOT BLOODED IN MORE WAYS THAN ONE")
  var text2:String;

  @:optional
  @:default("PROTECT YO NUTS")
  var text3:String;

  @:jignored
  var animationMap:Map<String, AnimationData>;

  @:jignored
  var prefixToOffsetsMap:Map<String, Array<Float>>;

  @:optional
  var cartoon:Null<PlayerFreeplayDJCartoonData>;

  public function new()
  {
    animationMap = new Map();
  }

  function mapAnimations()
  {
    if (animationMap == null) animationMap = new Map();
    if (prefixToOffsetsMap == null) prefixToOffsetsMap = new Map();

    animationMap.clear();
    prefixToOffsetsMap.clear();
    for (anim in animations)
    {
      animationMap.set(anim.name, anim);
      prefixToOffsetsMap.set(anim.prefix, anim.offsets);
    }
  }

  public function getAtlasPath():String
  {
    return Paths.animateAtlas(assetPath);
  }

  public function getFreeplayDJText(index:Int):String
  {
    switch (index)
    {
      case 1:
        return text1;
      case 2:
        return text2;
      case 3:
        return text3;
      default:
        return '';
    }
  }

  public function getAnimationPrefix(name:String):Null<String>
  {
    if (animationMap.size() == 0) mapAnimations();

    var anim = animationMap.get(name);
    if (anim == null) return null;
    return anim.prefix;
  }

  public function getAnimationOffsetsByPrefix(?prefix:String):Array<Float>
  {
    if (prefixToOffsetsMap.size() == 0) mapAnimations();
    if (prefix == null) return [0, 0];
    return prefixToOffsetsMap.get(prefix);
  }

  public function getAnimationOffsets(name:String):Array<Float>
  {
    return getAnimationOffsetsByPrefix(getAnimationPrefix(name));
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

typedef PlayerResultsData =
{
  var perfect:Array<PlayerResultsAnimationData>;
  var excellent:Array<PlayerResultsAnimationData>;
  var great:Array<PlayerResultsAnimationData>;
  var good:Array<PlayerResultsAnimationData>;
  var loss:Array<PlayerResultsAnimationData>;
};

typedef PlayerResultsAnimationData =
{
  /**
   * `sparrow` or `animate` or whatever
   */
  var renderType:String;

  var assetPath:String;

  @:optional
  @:default([0, 0])
  var offsets:Array<Float>;

  @:optional
  @:default(500)
  var zIndex:Int;

  @:optional
  @:default(0.0)
  var delay:Float;

  @:optional
  @:default(1.0)
  var scale:Float;

  @:optional
  @:default('')
  var startFrameLabel:Null<String>;

  @:optional
  var loopFrame:Null<Int>;

  @:optional
  var loopFrameLabel:Null<String>;
};

typedef PlayerFreeplayDJCartoonData =
{
  var soundClickFrame:Int;
  var soundCartoonFrame:Int;
  var loopBlinkFrame:Int;
  var loopFrame:Int;
  var channelChangeFrame:Int;
}
