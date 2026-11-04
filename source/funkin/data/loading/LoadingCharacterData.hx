package funkin.data.loading;

/**
 * Data for a character in the loading screen.
 */
typedef LoadingCharacterData =
{
  /**
   * The character's offsets.
   */
  var offsets:Array<Float>;

  /**
   * The character's scale.
   */
  var scale:Float;

  /**
   * The weight of the character.
   * A higher weight increases the chance of this character being chosen.
   */
  var weight:Float;

  /**
   * Defines how this character should be rendered based on the given type.
   * Can be either `sparrow`, `packer`, or `animateatlas`
   */
  @:optional
  @:default('sparrow')
  var ?renderType:String;

  /**
   * If this loading character is an animate atlas, you can provide additional settings for it here.
   */
  @:optional
  public var atlasSettings:Null<funkin.data.stage.StageData.TextureAtlasData>;
}
