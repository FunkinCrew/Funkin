package funkin.play.cutscene.dialogue;

/**
 * Data about a conversation.
 * Includes what speakers are in the conversation, and what phrases they say.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.SpeakerData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class SpeakerData
{
  public var version:String;
  public var name:String;
  public var assetPath:String;
  public var flipX:Bool;
  public var isPixel:Bool;
  public var offsets:Array<Float>;
  public var scale:Float;
  public var animations:Array<AnimationData>;

  public function new(version:String, name:String, assetPath:String, animations:Array<AnimationData>, ?offsets:Array<Float>, ?flipX:Bool = false,
      ?isPixel:Bool = false, ?scale:Float = 1.0)
  {
    this.version = version;
    this.name = name;
    this.assetPath = assetPath;
    this.animations = animations;

    this.offsets = offsets;
    if (this.offsets == null || this.offsets == []) this.offsets = [0, 0];

    this.flipX = flipX;
    this.isPixel = isPixel;
    this.scale = scale;
  }

  public static function fromString(i:String):SpeakerData
  {
    if (i == null || i == '') return null;
    var data:
      {
        version:String,
        name:String,
        assetPath:String,
        animations:Array<AnimationData>,
        ?offsets:Array<Float>,
        ?flipX:Bool,
        ?isPixel:Bool,
        ?scale:Float
      } = tink.Json.parse(i);
    return fromJson(data);
  }

  public static function fromJson(j:Dynamic):SpeakerData
  {
    // TODO: Check version and perform migrations if necessary.
    if (j == null) return null;
    return new SpeakerData(j.version, j.name, j.assetPath, j.animations, j.offsets, j.flipX, j.isPixel, j.scale);
  }

  public function toJson():Dynamic
  {
    var result:Dynamic =
      {
        version: this.version,
        name: this.name,
        assetPath: this.assetPath,
        animations: this.animations,
        flipX: this.flipX,
        isPixel: this.isPixel
      };

    if (this.scale != 1.0) result.scale = this.scale;

    return result;
  }
}
