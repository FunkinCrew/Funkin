package funkin.data.song.migrator;

import thx.semver.Version;
import funkin.data.song.SongData;

class SongMetadata_v2_0_0
{
  // ==========
  // MODIFIED VALUES
  // ===========

  /**
   * In metadata `v2.1.0`, `SongPlayData` was refactored.
   */
  public var playData:SongPlayData_v2_0_0;

  /**
   * In metadata `v2.1.0`, `variation` was set to `ignore` when writing.
   */
  @:optional
  @:default('default')
  public var variation:String;

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

  public function new() {}

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongMetadata[LEGACY:v2.0.0](${this.songName} by ${this.artist}, variation ${this.variation})';
  }
}

class SongPlayData_v2_0_0
{
  // ==========
  // MODIFIED VALUES
  // ===========

  /**
   * In metadata version `v2.1.0`, this was refactored to a single `SongCharacterData` object.
   */
  public var playableChars:Map<String, SongPlayableChar_v2_0_0>;

  /**
   * In metadata version `v2.2.0`, this was renamed to `noteStyle`.
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

  public var stage:String;

  public function new() {}

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongPlayData[LEGACY:v2.0.0](${this.songVariations}, ${this.difficulties})';
  }
}

class SongPlayableChar_v2_0_0
{
  @:alias('g')
  @:optional
  @:default('')
  public var girlfriend:String = '';

  @:alias('o')
  @:optional
  @:default('')
  public var opponent:String = '';

  @:alias('i')
  @:optional
  @:default('')
  public var inst:String = '';

  public function new(girlfriend:String = '', opponent:String = '', inst:String = '')
  {
    this.girlfriend = girlfriend;
    this.opponent = opponent;
    this.inst = inst;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongPlayableChar[LEGACY:v2.0.0](${this.girlfriend}, ${this.opponent}, ${this.inst})';
  }
}
