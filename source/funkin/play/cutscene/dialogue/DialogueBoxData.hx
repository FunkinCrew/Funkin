package funkin.play.cutscene.dialogue;

import funkin.data.animation.AnimationData;
import funkin.util.SerializerUtil;

/**
 * Data about a text box.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.DialogueBoxData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class DialogueBoxData
{
  public var version:String;
  public var name:String;
  public var assetPath:String;
  public var flipX:Bool;
  public var flipY:Bool;
  public var isPixel:Bool;
  public var offsets:Array<Float>;
  public var text:DialogueBoxTextData;
  public var scale:Float;
  public var animations:Array<AnimationData>;

  public function new(version:String, name:String, assetPath:String, flipX:Bool = false, flipY:Bool = false, isPixel:Bool = false, offsets:Null<Array<Float>>,
      text:DialogueBoxTextData, scale:Float = 1.0, animations:Array<AnimationData>)
  {
    this.version = version;
    this.name = name;
    this.assetPath = assetPath;
    this.flipX = flipX;
    this.flipY = flipY;
    this.isPixel = isPixel;
    this.offsets = offsets ?? [0, 0];
    this.text = text;
    this.scale = scale;
    this.animations = animations;
  }

  public static function fromString(i:String):DialogueBoxData
  {
    if (i == null || i == '') return null;
    var data:
      {
        version:String,
        name:String,
        assetPath:String,
        flipX:Bool,
        flipY:Bool,
        isPixel:Bool,
        ?offsets:Array<Float>,
        text:Dynamic,
        scale:Float,
        animations:Array<AnimationData>
      } = tink.Json.parse(i);
    return fromJson(data);
  }

  public static function fromJson(j:Dynamic):DialogueBoxData
  {
    // TODO: Check version and perform migrations if necessary.
    if (j == null) return null;
    return new DialogueBoxData(j.version, j.name, j.assetPath, j.flipX, j.flipY, j.isPixel, j.offsets, DialogueBoxTextData.fromJson(j.text), j.scale,
      j.animations);
  }

  public function toJson():Dynamic
  {
    return {
      version: this.version,
      name: this.name,
      assetPath: this.assetPath,
      flipX: this.flipX,
      flipY: this.flipY,
      isPixel: this.isPixel,
      offsets: this.offsets,
      scale: this.scale,
      animations: this.animations
    };
  }
}

/**
 * Data about text in a text box.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.DialogueBoxTextData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class DialogueBoxTextData
{
  public var offsets:Array<Float>;
  public var width:Int;
  public var size:Int;
  public var color:String;
  public var shadowColor:Null<String>;
  public var shadowWidth:Null<Int>;

  public function new(offsets:Null<Array<Float>>, width:Null<Int>, size:Null<Int>, color:String, shadowColor:Null<String>, shadowWidth:Null<Int>)
  {
    this.offsets = offsets ?? [0, 0];
    this.width = width ?? 300;
    this.size = size ?? 32;
    this.color = color;
    this.shadowColor = shadowColor;
    this.shadowWidth = shadowWidth;
  }

  public static function fromJson(j:Dynamic):DialogueBoxTextData
  {
    // TODO: Check version and perform migrations if necessary.
    if (j == null) return null;
    return new DialogueBoxTextData(j.offsets, j.width, j.size, j.color, j.shadowColor, j.shadowWidth);
  }

  public function toJson():Dynamic
  {
    return {
      offsets: this.offsets,
      width: this.width,
      size: this.size,
      color: this.color,
      shadowColor: this.shadowColor,
      shadowWidth: this.shadowWidth,
    };
  }
}
