package funkin.play.cutscene.dialogue;

import funkin.util.SerializerUtil;

/**
 * Data about a conversation.
 * Includes what speakers are in the conversation, and what phrases they say.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.ConversationData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class ConversationData
{
  public var version:String;
  public var backdrop:BackdropData;
  public var outro:OutroData;
  public var music:MusicData;
  public var dialogue:Array<DialogueEntryData>;

  public function new(version:String, backdrop:BackdropData, outro:OutroData, music:MusicData, dialogue:Array<DialogueEntryData>)
  {
    this.version = version;
    this.backdrop = backdrop;
    this.outro = outro;
    this.music = music;
    this.dialogue = dialogue;
  }

  public static function fromString(i:String):ConversationData
  {
    if (i == null || i == '') return null;
    var data:
      {
        version:String,
        backdrop:Dynamic, // TODO: tink.Json doesn't like when these are typed
        ?outro:Dynamic, // TODO: tink.Json doesn't like when these are typed
        ?music:Dynamic, // TODO: tink.Json doesn't like when these are typed
        dialogue:Array<Dynamic> // TODO: tink.Json doesn't like when these are typed
      } = tink.Json.parse(i);
    return fromJson(data);
  }

  public static function fromJson(j:Dynamic):ConversationData
  {
    // TODO: Check version and perform migrations if necessary.
    if (j == null) return null;
    return new ConversationData(j.version, BackdropData.fromJson(j.backdrop), OutroData.fromJson(j.outro), MusicData.fromJson(j.music),
      j.dialogue.map(d -> DialogueEntryData.fromJson(d)));
  }

  public function toJson():Dynamic
  {
    return {
      version: this.version,
      backdrop: this.backdrop.toJson(),
      dialogue: this.dialogue.map(d -> d.toJson())
    };
  }
}

/**
 * Data about a single dialogue entry.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.ConversationData.DialogueEntryData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class DialogueEntryData
{
  /**
   * The speaker who says this phrase.
   */
  public var speaker:String;

  /**
   * The animation the speaker will play.
   */
  public var speakerAnimation:String;

  /**
   * The text box that will appear.
   */
  public var box:String;

  /**
   * The animation the dialogue box will play.
   */
  public var boxAnimation:String;

  /**
   * The lines of text that will appear in the text box.
   */
  public var text:Array<String>;

  /**
   * The relative speed at which the text will scroll.
   * @default 1.0
   */
  public var speed:Float = 1.0;

  public function new(speaker:String, speakerAnimation:String, box:String, boxAnimation:String, text:Array<String>, speed:Float = null)
  {
    this.speaker = speaker;
    this.speakerAnimation = speakerAnimation;
    this.box = box;
    this.boxAnimation = boxAnimation;
    this.text = text;
    if (speed != null) this.speed = speed;
  }

  public static function fromJson(j:Dynamic):DialogueEntryData
  {
    if (j == null) return null;
    return new DialogueEntryData(j.speaker, j.speakerAnimation, j.box, j.boxAnimation, j.text, j.speed);
  }

  public function toJson():Dynamic
  {
    var result:Dynamic =
      {
        speaker: this.speaker,
        speakerAnimation: this.speakerAnimation,
        box: this.box,
        boxAnimation: this.boxAnimation,
        text: this.text,
      };

    if (this.speed != 1.0) result.speed = this.speed;

    return result;
  }
}

/**
 * Data about a backdrop.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.ConversationData.BackdropData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class BackdropData
{
  public var type:BackdropType;
  public var data:Dynamic;

  public function new(typeStr:String, data:Dynamic)
  {
    this.type = typeStr;
    this.data = data;
  }

  public static function fromJson(j:Dynamic):BackdropData
  {
    if (j == null) return null;
    return new BackdropData(j.type, j.data);
  }

  public function toJson():Dynamic
  {
    return {
      type: this.type,
      data: this.data
    };
  }
}

enum abstract BackdropType(String) from String to String
{
  public var SOLID:BackdropType = 'solid';
}

/**
 * Data about a music track.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.ConversationData.MusicData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class MusicData
{
  public var asset:String;

  public var fadeTime:Float;

  @:optional
  @:default(false)
  public var looped:Bool;

  public function new(asset:String, looped:Bool, fadeTime:Float = 0.0)
  {
    this.asset = asset;
    this.looped = looped;
    this.fadeTime = fadeTime;
  }

  public static function fromJson(j:Dynamic):MusicData
  {
    if (j == null) return null;
    return new MusicData(j.asset, j.looped, j.fadeTime);
  }

  public function toJson():Dynamic
  {
    return {
      asset: this.asset,
      looped: this.looped,
      fadeTime: this.fadeTime
    };
  }
}

/**
 * Data about an outro.
 */
@:jsonParse(j -> funkin.play.cutscene.dialogue.ConversationData.OutroData.fromJson(j))
@:jsonStringify(v -> v.toJson())
class OutroData
{
  public var type:OutroType;
  public var data:Dynamic;

  public function new(?typeStr:String, data:Dynamic)
  {
    this.type = typeStr ?? OutroType.NONE;
    this.data = data;
  }

  public static function fromJson(j:Dynamic):OutroData
  {
    if (j == null) return null;
    return new OutroData(j.type, j.data);
  }

  public function toJson():Dynamic
  {
    return {
      type: this.type,
      data: this.data
    };
  }
}

enum abstract OutroType(String) from String to String
{
  public var NONE:OutroType = 'none';
  public var FADE:OutroType = 'fade';
}
