package funkin.data.character.migrator;

import funkin.data.character.CharacterData;

typedef CharacterData_v1_0_0 =
{
  var version:String;

  var name:String;

  @:optional
  @:default('sparrow')
  var renderType:CharacterRenderType;

  var assetPath:String;

  @:optional
  @:default(1.0)
  var scale:Null<Float>;

  @:optional
  var healthIcon:Null<HealthIconData>;

  @:optional
  var death:Null<DeathData>;

  @:optional
  @:default([0, 0])
  var offsets:Null<Array<Float>>;

  @:optional
  @:default([0, 0])
  var cameraOffsets:Array<Float>;

  @:optional
  @:default(false)
  var isPixel:Null<Bool>;

  @:optional
  @:default(1.0)
  var danceEvery:Null<Float>;

  @:optional
  @:default(8.0)
  var singTime:Null<Float>;

  var animations:Array<AnimationData_v1_0_0>;

  @:optional
  @:default('idle')
  var startingAnimation:Null<String>;

  @:optional
  @:default(false)
  var flipX:Null<Bool>;
};

typedef AnimationData_v1_0_0 =
{
  @:optional
  var prefix:String;

  @:optional
  var assetPath:Null<String>;

  @:default([0, 0])
  @:optional
  var offsets:Null<Array<Float>>;

  @:default(false)
  @:optional
  var looped:Bool;

  @:default(false)
  @:optional
  var flipX:Null<Bool>;

  @:default(false)
  @:optional
  var flipY:Null<Bool>;

  @:default(24)
  @:optional
  var frameRate:Null<Int>;

  @:default([])
  @:optional
  var frameIndices:Null<Array<Int>>;

  var name:String;
}
