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
   * The default sticker pack to use for songs featuring this playable character.
   * Can be overridden by specific songs.
   * @default `default`
   */
  @:optional
  @:default(funkin.util.Constants.DEFAULT_STICKER_PACK)
  public var stickerPack:String = Constants.DEFAULT_STICKER_PACK;

  /**
   * Which freeplay style to use for this character.
   */
  @:optional
  @:default("bf")
  public var freeplayStyle:String = Constants.DEFAULT_FREEPLAY_STYLE;

  /**
   * Data for displaying this character in the Freeplay menu.
   * If null, display no DJ.
   */
  @:optional
  public var freeplayDJ:Null<PlayerFreeplayDJData> = null;

  /**
   * Data for displaying this character in the Character Select menu.
   * If null, exclude from Character Select.
   */
  @:optional
  public var charSelect:Null<PlayerCharSelectData> = null;

  /**
   * Data for displaying this character in the results screen.
   */
  @:optional
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
  var charSelect:Null<PlayerFreeplayDJCharSelectData>;

  @:optional
  var cartoon:Null<PlayerFreeplayDJCartoonData>;

  @:optional
  var fistPump:Null<PlayerFreeplayDJFistPumpData>;

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

  public function getFistPumpIntroStartFrame():Int
  {
    return fistPump?.introStartFrame ?? 0;
  }

  public function getFistPumpIntroEndFrame():Int
  {
    return fistPump?.introEndFrame ?? 0;
  }

  public function getFistPumpLoopStartFrame():Int
  {
    return fistPump?.loopStartFrame ?? 0;
  }

  public function getFistPumpLoopEndFrame():Int
  {
    return fistPump?.loopEndFrame ?? 0;
  }

  public function getFistPumpIntroBadStartFrame():Int
  {
    return fistPump?.introBadStartFrame ?? 0;
  }

  public function getFistPumpIntroBadEndFrame():Int
  {
    return fistPump?.introBadEndFrame ?? 0;
  }

  public function getFistPumpLoopBadStartFrame():Int
  {
    return fistPump?.loopBadStartFrame ?? 0;
  }

  public function getFistPumpLoopBadEndFrame():Int
  {
    return fistPump?.loopBadEndFrame ?? 0;
  }

  public function getCharSelectTransitionDelay():Float
  {
    return charSelect?.transitionDelay ?? 0.25;
  }
}

class PlayerCharSelectData
{
  /**
   * A zero-indexed number for the character's preferred position in the grid.
   * 0 = top left, 4 = center, 8 = bottom right
   * In the event of a conflict, the first character alphabetically gets it,
   * and others get shifted over.
   */
  @:optional
  public var position:Null<Int>;

  /**
   * The GF name to assign for this character.
   */
  @:optional
  public var gf:PlayerCharSelectGFData;
}

typedef PlayerCharSelectGFData =
{
  @:optional
  public var assetPath:String;

  @:optional
  public var animInfoPath:String;

  @:optional
  @:default(false)
  public var visualizer:Bool;
}

typedef PlayerResultsData =
{
  var music:PlayerResultsMusicData;

  var perfectGold:Array<PlayerResultsAnimationData>;
  var perfect:Array<PlayerResultsAnimationData>;
  var excellent:Array<PlayerResultsAnimationData>;
  var great:Array<PlayerResultsAnimationData>;
  var good:Array<PlayerResultsAnimationData>;
  var loss:Array<PlayerResultsAnimationData>;
};

typedef PlayerResultsMusicData =
{
  @:optional
  var PERFECT_GOLD:String;

  @:optional
  var PERFECT:String;

  @:optional
  var EXCELLENT:String;

  @:optional
  var GREAT:String;

  @:optional
  var GOOD:String;

  @:optional
  var SHIT:String;
}

typedef PlayerResultsAnimationData =
{
  /**
   * `sparrow` or `animate` or whatever
   */
  var renderType:String;

  @:optional
  var assetPath:Null<String>;

  @:optional
  var scriptClass:Null<String>;

  @:optional
  @:default([0, 0])
  var offsets:Array<Float>;

  @:optional
  @:default("both")
  var filter:String;

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
  @:default('')
  var sound:Null<String>;

  @:optional
  @:default(true)
  var looped:Bool;

  @:optional
  var loopFrame:Null<Int>;

  @:optional
  var loopFrameLabel:Null<String>;
};

typedef PlayerFreeplayDJCharSelectData =
{
  var transitionDelay:Float;
}

typedef PlayerFreeplayDJCartoonData =
{
  var soundClickFrame:Int;
  var soundCartoonFrame:Int;
  var loopBlinkFrame:Int;
  var loopFrame:Int;
  var channelChangeFrame:Int;
}

typedef PlayerFreeplayDJFistPumpData =
{
  @:default(0)
  var introStartFrame:Int;

  @:default(4)
  var introEndFrame:Int;

  @:default(4)
  var loopStartFrame:Int;

  @:default(-1)
  var loopEndFrame:Int;

  @:default(0)
  var introBadStartFrame:Int;

  @:default(4)
  var introBadEndFrame:Int;

  @:default(4)
  var loopBadStartFrame:Int;

  @:default(-1)
  var loopBadEndFrame:Int;
};
