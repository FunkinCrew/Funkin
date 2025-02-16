package funkin.data.freeplay.album;

import funkin.data.animation.AnimationData;

/**
 * A type definition for the data for an album of songs.
 * It includes things like what graphics to display in Freeplay.
 * @see https://lib.haxe.org/p/json2object/
 */
typedef AlbumData =
{
  /**
   * Semantic version for album data.
   */
  public var version:String;

  /**
   * Readable name of the album.
   */
  public var name:String;

  /**
   * Readable name of the artist(s) of the album.
   */
  public var artists:Array<String>;

  /**
   * Asset key for the album art.
   * The album art will be displayed in Freeplay.
   */
  public var albumArtAsset:String;

  /**
   * Asset key for the album title.
   * The album title will be displayed below the album art in Freeplay.
   */
  public var albumTitleAsset:String;

  /**
   * Offsets for the album title.
   */
  @:optional
  @:default([0, 0])
  public var albumTitleOffsets:Null<Array<Float>>;

  /**
   * An optional array of animations for the album title.
   */
  @:optional
  @:default([])
  public var albumTitleAnimations:Array<AnimationData>;
}
