package funkin.data.notestyle;

import haxe.DynamicAccess;
import funkin.data.animation.AnimationData;

/**
 * A type definition for the data in a note style JSON file.
 * @see https://lib.haxe.org/p/json2object/
 */
typedef NoteStyleData =
{
  /**
   * The version number of the note style data schema.
   * When making changes to the note style data format, this should be incremented,
   * and a migration function should be added to NoteStyleDataParser to handle old versions.
   */
  @:default(funkin.data.notestyle.NoteStyleRegistry.NOTE_STYLE_DATA_VERSION)
  var version:String;

  /**
   * The readable title of the note style.
   */
  var name:String;

  /**
   * The author of the note style.
   */
  var author:String;

  /**
   * The note style to use as a fallback/parent.
   * @default null
   */
  @:optional
  var fallback:Null<String>;

  /**
   * Data for each of the assets in the note style.
   */
  var assets:NoteStyleAssetsData;
}

typedef NoteStyleAssetsData =
{
  /**
   * The sprites for the notes.
   * @default The sprites from the fallback note style.
   */
  @:optional
  var note:NoteStyleAssetData<NoteStyleData_Note>;

  /**
   * The sprites for the hold notes.
   * @default The sprites from the fallback note style.
   */
  @:optional
  var holdNote:NoteStyleAssetData<NoteStyleData_HoldNote>;

  /**
   * The sprites for the strumline.
   * @default The sprites from the fallback note style.
   */
  @:optional
  var noteStrumline:NoteStyleAssetData<NoteStyleData_NoteStrumline>;

  /**
   * The sprites for the note splashes.
   * @default The sprites from the fallback note style.
   */
  @:optional
  var noteSplash:NoteStyleAssetData<NoteStyleData_NoteSplash>;

  /**
   * The sprites for the hold note covers.
   */
  @:optional
  var holdNoteCover:NoteStyleAssetData<NoteStyleData_HoldNoteCover>;
}

/**
 * Data shared by all note style assets.
 */
typedef NoteStyleAssetData<T> =
{
  /**
   * The image to use for the asset. May be a Sparrow sprite sheet.
   */
  var assetPath:String;

  /**
   * The scale to render the prop at.
   * @default 1.0
   */
  @:default(1.0)
  @:optional
  var scale:Float;

  /**
   * Offset the sprite's position by this amount.
   * @default [0, 0]
   */
  @:default([0, 0])
  @:optional
  var offsets:Null<Array<Float>>;

  /**
   * If true, the prop is a pixel sprite, and will be rendered without anti-aliasing.
   */
  @:default(false)
  @:optional
  var isPixel:Bool;

  /**
   * The structure of this data depends on the asset.
   */
  var data:T;
}

typedef NoteStyleData_Note =
{
  var left:UnnamedAnimationData;
  var down:UnnamedAnimationData;
  var up:UnnamedAnimationData;
  var right:UnnamedAnimationData;
}

typedef NoteStyleData_HoldNote = {}

/**
 * Data on animations for each direction of the strumline.
 */
typedef NoteStyleData_NoteStrumline =
{
  var leftStatic:UnnamedAnimationData;
  var leftPress:UnnamedAnimationData;
  var leftConfirm:UnnamedAnimationData;
  var leftConfirmHold:UnnamedAnimationData;
  var downStatic:UnnamedAnimationData;
  var downPress:UnnamedAnimationData;
  var downConfirm:UnnamedAnimationData;
  var downConfirmHold:UnnamedAnimationData;
  var upStatic:UnnamedAnimationData;
  var upPress:UnnamedAnimationData;
  var upConfirm:UnnamedAnimationData;
  var upConfirmHold:UnnamedAnimationData;
  var rightStatic:UnnamedAnimationData;
  var rightPress:UnnamedAnimationData;
  var rightConfirm:UnnamedAnimationData;
  var rightConfirmHold:UnnamedAnimationData;
}

typedef NoteStyleData_NoteSplash =
{
  @:optional
  var splash1Left:UnnamedAnimationData;

  @:optional
  var splash1Down:UnnamedAnimationData;

  @:optional
  var splash1Up:UnnamedAnimationData;

  @:optional
  var splash1Right:UnnamedAnimationData;

  @:optional
  var splash2Left:UnnamedAnimationData;

  @:optional
  var splash2Down:UnnamedAnimationData;

  @:optional
  var splash2Up:UnnamedAnimationData;

  @:optional
  var splash2Right:UnnamedAnimationData;

  /**
   * If false, note splashes are entirely hidden on this note style.
   * @default Note splashes are enabled.
   */
  @:optional
  @:default(true)
  var enabled:Bool;
};

typedef NoteStyleData_HoldNoteCover =
{
  /**
   * If false, hold note covers are entirely hidden on this note style.
   * @default Hold note covers are enabled.
   */
  @:optional
  @:default(true)
  var enabled:Bool;
};
