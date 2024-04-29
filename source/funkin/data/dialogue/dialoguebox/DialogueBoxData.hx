package funkin.data.dialogue.dialoguebox;

import funkin.data.animation.AnimationData;

/**
 * A type definition for the data for a conversation text box.
 * It includes things like the sprite to use, and the font and color for the text.
 * The actual text is included in the ConversationData.
 * @see https://lib.haxe.org/p/json2object/
 */
typedef DialogueBoxData =
{
  /**
   * Semantic version for dialogue box data.
   */
  public var version:String;

  /**
   * A human readable name for the dialogue box type.
   */
  public var name:String;

  /**
   * The asset path for the sprite to use for the dialogue box.
   * Takes a static sprite or a sprite sheet.
   */
  public var assetPath:String;

  /**
   * Whether to horizontally flip the dialogue box sprite.
   */
  @:optional
  @:default(false)
  public var flipX:Bool;

  /**
   * Whether to vertically flip the dialogue box sprite.
   */
  @:optional
  @:default(false)
  public var flipY:Bool;

  /**
   * Whether to disable anti-aliasing for the dialogue box sprite.
   */
  @:optional
  @:default(false)
  public var isPixel:Bool;

  /**
   * The relative horizontal and vertical offsets for the dialogue box sprite.
   */
  @:optional
  @:default([0, 0])
  public var offsets:Array<Float>;

  /**
   * Info about how to display text in the dialogue box.
   */
  public var text:DialogueBoxTextData;

  /**
   * Multiply the size of the dialogue box sprite.
   */
  @:optional
  @:default(1)
  public var scale:Float;

  /**
   * If using a spritesheet for the dialogue box, the animations to use.
   */
  @:optional
  @:default([])
  public var animations:Array<AnimationData>;
}

typedef DialogueBoxTextData =
{
  /**
   * The position of the text in teh box.
   */
  @:optional
  @:default([0, 0])
  var offsets:Array<Float>;

  /**
   * The width of the
   */
  @:optional
  @:default(300)
  var width:Int;

  /**
   * The font size to use for the text.
   */
  @:optional
  @:default(32)
  var size:Int;

  /**
   * The color to use for the text.
   * Use a string that can be translated to a color, like `#FF0000` for red.
   */
  @:optional
  @:default("#000000")
  var color:String;

  /**
   * The font to use for the text.
   * @since v1.1.0
   * @default `Arial`, make sure to switch this!
   */
  @:optional
  @:default("Arial")
  var fontFamily:String;

  /**
   * The color to use for the shadow of the text. Use transparent to disable.
   */
  var shadowColor:String;

  /**
   * The width of the shadow of the text.
   */
  @:optional
  @:default(0)
  var shadowWidth:Int;
};
