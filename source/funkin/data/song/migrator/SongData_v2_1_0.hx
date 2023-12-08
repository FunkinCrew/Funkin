package funkin.data.song.migrator;

import funkin.data.song.SongData;
import funkin.data.song.SongRegistry;
import thx.semver.Version;

@:nullSafety
class SongMetadata_v2_1_0
{
  // ==========
  // MODIFIED VALUES
  // ===========

  /**
   * In metadata `v2.2.0`, `SongPlayData` was refactored.
   */
  public var playData:SongPlayData_v2_1_0;

  // In metadata `v2.2.1`, `SongOffsets` was added.
  // var offsets:SongOffsets;
  // ==========
  // UNMODIFIED VALUES
  // ==========
  @:jcustomparse(funkin.data.DataParse.semverVersion)
  @:jcustomwrite(funkin.data.DataWrite.semverVersion)
  public var version:Version;

  @:default("Unknown")
  public var songName:String;

  @:default("Unknown")
  public var artist:String;

  @:optional
  @:default(96)
  public var divisions:Null<Int>; // Optional field

  @:optional
  @:default(false)
  public var looped:Bool;

  @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  public var timeFormat:SongData.SongTimeFormat;

  public var timeChanges:Array<SongData.SongTimeChange>;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  public function new(songName:String, artist:String, ?variation:String)
  {
    this.version = SongRegistry.SONG_METADATA_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.looped = false;
    this.playData = new SongPlayData_v2_1_0();
    this.playData.songVariations = [];
    this.playData.difficulties = [];
    this.playData.characters = new SongCharacterData('bf', 'gf', 'dad');
    this.playData.stage = 'mainStage';
    this.playData.noteSkin = 'funkin';
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    // Variation ID.
    this.variation = (variation == null) ? Constants.DEFAULT_VARIATION : variation;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongMetadata[LEGACY:v2.1.0](${this.songName} by ${this.artist}, variation ${this.variation})';
  }
}

class SongPlayData_v2_1_0
{
  /**
   * In `v2.2.0`, this value was renamed to `noteStyle`.
   */
  public var noteSkin:String;

  // In 2.2.0, the ratings value was added.
  // In 2.2.0, the album value was added.
  // ==========
  // UNMODIFIED VALUES
  // ==========
  @:default([])
  @:optional
  public var songVariations:Array<String>;
  public var difficulties:Array<String>;
  public var characters:SongData.SongCharacterData;
  public var stage:String;

  public function new() {}

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongPlayData[LEGACY:v2.1.0](${this.songVariations}, ${this.difficulties})';
  }
}
