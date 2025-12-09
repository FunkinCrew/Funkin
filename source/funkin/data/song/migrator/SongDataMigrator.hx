package funkin.data.song.migrator;

import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongPlayData;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.migrator.SongData_v2_0_0.SongMetadata_v2_0_0;
import funkin.data.song.migrator.SongData_v2_0_0.SongPlayData_v2_0_0;
import funkin.data.song.migrator.SongData_v2_0_0.SongPlayableChar_v2_0_0;

using funkin.data.song.migrator.SongDataMigrator; // Does this even work lol?

/**
 * This class contains functions to migrate older data formats to the current one.
 *
 * Utilizes static extensions with overloaded inline functions to make migration as easy as `.migrate()`.
 * @see https://try.haxe.org/#e1c1cf22
 */
class SongDataMigrator
{
  public static overload extern inline function migrate(input:SongData_v2_1_0.SongMetadata_v2_1_0):SongMetadata
  {
    return migrate_SongMetadata_v2_1_0(input);
  }

  public static function migrate_SongMetadata_v2_1_0(input:SongData_v2_1_0.SongMetadata_v2_1_0):SongMetadata
  {
    var result:SongMetadata = new SongMetadata(input.songName, input.artist, Constants.DEFAULT_CHARTER, input.variation);
    result.version = SongRegistry.SONG_METADATA_VERSION;
    result.timeFormat = input.timeFormat;
    result.divisions = input.divisions;
    result.timeChanges = input.timeChanges;
    result.looped = input.looped;
    result.playData = input.playData.migrate();
    result.generatedBy = input.generatedBy;

    return result;
  }

  public static overload extern inline function migrate(input:SongData_v2_1_0.SongPlayData_v2_1_0):SongPlayData
  {
    return migrate_SongPlayData_v2_1_0(input);
  }

  public static function migrate_SongPlayData_v2_1_0(input:SongData_v2_1_0.SongPlayData_v2_1_0):SongPlayData
  {
    var result:SongPlayData = new SongPlayData();
    result.songVariations = input.songVariations;
    result.difficulties = input.difficulties;
    result.stage = input.stage;
    result.characters = input.characters;

    // Renamed
    result.noteStyle = input.noteSkin;

    // Added
    result.ratings = ['default' => 1];
    result.album = null;

    return result;
  }

  public static overload extern inline function migrate(input:SongData_v2_0_0.SongMetadata_v2_0_0):SongMetadata
  {
    return migrate_SongMetadata_v2_0_0(input);
  }

  public static function migrate_SongMetadata_v2_0_0(input:SongData_v2_0_0.SongMetadata_v2_0_0):SongMetadata
  {
    var result:SongMetadata = new SongMetadata(input.songName, input.artist, Constants.DEFAULT_CHARTER, input.variation);
    result.version = SongRegistry.SONG_METADATA_VERSION;
    result.timeFormat = input.timeFormat;
    result.divisions = input.divisions;
    result.timeChanges = input.timeChanges;
    result.looped = input.looped;
    result.playData = input.playData.migrate();
    result.generatedBy = input.generatedBy;

    return result;
  }

  public static overload extern inline function migrate(input:SongData_v2_0_0.SongPlayData_v2_0_0):SongPlayData
  {
    return migrate_SongPlayData_v2_0_0(input);
  }

  public static function migrate_SongPlayData_v2_0_0(input:SongData_v2_0_0.SongPlayData_v2_0_0):SongPlayData
  {
    var result:SongPlayData = new SongPlayData();
    result.songVariations = input.songVariations;
    result.difficulties = input.difficulties;
    result.stage = input.stage;

    // Added
    result.ratings = ['default' => 1];
    result.album = null;

    // Renamed
    result.noteStyle = input.noteSkin;

    // Fetch the first playable character and migrate it.
    var firstCharKey:Null<String> = input.playableChars.size() == 0 ? null : input.playableChars.keys().array()[0];
    var firstCharData:Null<SongPlayableChar_v2_0_0> = input.playableChars.get(firstCharKey);

    if (firstCharData == null)
    {
      // Fill in a default playable character.
      result.characters = new SongCharacterData('bf', 'gf', 'dad');
    }
    else
    {
      result.characters = new SongCharacterData(firstCharKey, firstCharData.girlfriend, firstCharData.opponent, firstCharData.inst);
    }

    return result;
  }
}
