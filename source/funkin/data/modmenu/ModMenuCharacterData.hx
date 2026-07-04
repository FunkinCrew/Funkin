package funkin.data.modmenu;

import funkin.data.animation.AnimationData;

/**
 * Data for a character in the mod menu.
 */
typedef ModMenuCharacterData =
{
  /**
   * Optional render type for the character. Defaults to using texture atlases.
   */
  @:optional @:default('animateatlas')
  var renderType:String;

  /**
   * Optional list of animations for the character.
   */
  @:optional
  var animations:Array<AnimationData>;

  /**
   * Optional settings for the character's texture atlas, if it is one.
   */
  @:optional
  var atlasSettings:funkin.data.stage.StageData.TextureAtlasData;

  /**
   * The global offsets for the character's position.
   */
  @:optional @:default([0, 0])
  var offsets:Array<Float>;

  /**
   * The local offsets for the character's position.
   */
  @:optional @:default([0, 0])
  var localOffsets:Array<Float>;

  /**
   * The scale of the character.
   */
  @:optional @:default(1)
  var scale:Float;
}
