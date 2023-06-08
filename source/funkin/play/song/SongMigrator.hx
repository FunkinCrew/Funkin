package funkin.play.song;

import funkin.play.song.formats.FNFLegacy;
import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongMetadata;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongData.SongPlayableChar;
import funkin.util.VersionUtil;

class SongMigrator
{
  /**
   * The current latest version string for the song data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the SongMigrator class.
   */
  public static final CHART_VERSION:String = '2.0.0';

  /**
   * Version rule for which chart versions are compatible with the current version.
   */
  public static final CHART_VERSION_RULE:String = '2.0.x';

  /**
   * Migrate song data from an older chart version to the current version.
   * @param jsonData The song metadata to migrate.
   * @param songId The ID of the song (only used for error reporting).
   * @return The migrated song metadata, or null if the migration failed.
   */
  public static function migrateSongMetadata(jsonData:Dynamic, songId:String):SongMetadata
  {
    if (jsonData.version != null)
    {
      if (VersionUtil.validateVersion(jsonData.version, CHART_VERSION_RULE))
      {
        trace('Song (${songId}) metadata version (${jsonData.version}) is valid and up-to-date.');

        var songMetadata:SongMetadata = cast jsonData;

        return songMetadata;
      }
      else
      {
        trace('Song (${songId}) metadata version (${jsonData.version}) is outdated.');
        switch (jsonData.version)
        {
          case '1.0.0':
            return migrateSongMetadataFromLegacy(jsonData);
          default:
            trace('Song (${songId}) has unknown metadata version (${jsonData.version}), assuming FNF Legacy.');
            return migrateSongMetadataFromLegacy(jsonData);
        }
      }
    }
    else
    {
      trace('Song metadata version is missing.');
    }
    return null;
  }

  /**
   * Migrate song chart data from an older chart version to the current version.
   * @param jsonData The song chart data to migrate.
   * @param songId The ID of the song (only used for error reporting).
   * @return The migrated song chart data, or null if the migration failed.
   */
  public static function migrateSongChartData(jsonData:Dynamic, songId:String):SongChartData
  {
    if (jsonData.version)
    {
      if (VersionUtil.validateVersion(jsonData.version, CHART_VERSION_RULE))
      {
        trace('Song (${songId}) chart version (${jsonData.version}) is valid and up-to-date.');

        var songChartData:SongChartData = cast jsonData;

        return songChartData;
      }
      else
      {
        trace('Song (${songId}) chart version (${jsonData.version}) is outdated.');
        switch (jsonData.version)
        {
          // TODO: Add migration functions as cases here.
          default:
            // Unknown version.
            trace('Song (${songId}) unknown chart version: ${jsonData.version}');
        }
      }
    }
    else
    {
      trace('Song chart version is missing.');
    }
    return null;
  }

  /**
   * Migrate song metadata from FNF Legacy chart version to the current version.
   * @param jsonData The song metadata to migrate.
   * @param songId The ID of the song (only used for error reporting).
   * @return The migrated song metadata, or null if the migration failed.
   */
  public static function migrateSongMetadataFromLegacy(jsonData:Dynamic):SongMetadata
  {
    trace('Migrating song metadata from FNF Legacy.');

    var songData:FNFLegacy = cast jsonData;

    var songMetadata:SongMetadata = new SongMetadata('Import', 'Kawai Sprite', 'default');

    var hadError:Bool = false;

    // Set generatedBy string for debugging.
    songMetadata.generatedBy = 'Chart Editor Import (FNF Legacy)';

    try
    {
      // Set the song's BPM.
      songMetadata.timeChanges[0].bpm = songData.song.bpm;
    }
    catch (e)
    {
      trace("Couldn't parse BPM!");
      hadError = true;
    }

    try
    {
      // Set the song's stage.
      songMetadata.playData.stage = songData.song.stageDefault;
    }
    catch (e)
    {
      trace("Couldn't parse stage!");
      hadError = true;
    }

    try
    {
      // Set's the song's name.
      songMetadata.songName = songData.song.song;
    }
    catch (e)
    {
      trace("Couldn't parse song name!");
      hadError = true;
    }

    songMetadata.playData.difficulties = [];
    if (songData.song != null && songData.song.notes != null)
    {
      if (songData.song.notes.easy != null) songMetadata.playData.difficulties.push('easy');
      if (songData.song.notes.normal != null) songMetadata.playData.difficulties.push('normal');
      if (songData.song.notes.hard != null) songMetadata.playData.difficulties.push('hard');
    }
    else
    {
      trace("Couldn't parse difficulties!");
      hadError = true;
    }

    songMetadata.playData.songVariations = [];

    // Set the song's song variations.
    songMetadata.playData.playableChars = {};
    try
    {
      Reflect.setField(songMetadata.playData.playableChars, songData.song.player1, new SongPlayableChar('', songData.song.player2));
    }
    catch (e)
    {
      trace("Couldn't parse characters!");
      hadError = true;
    }

    return songMetadata;
  }

  /**
   * Migrate song chart data from FNF Legacy chart version to the current version.
   * @param jsonData The song data to migrate.
   * @param songId The ID of the song (only used for error reporting).
   * @param difficulty The difficulty to migrate.
   * @return The migrated song chart data, or null if the migration failed.
   */
  public static function migrateSongChartDataFromLegacy(jsonData:Dynamic):SongChartData
  {
    trace('Migrating song chart data from FNF Legacy.');

    var songData:FNFLegacy = cast jsonData;

    var songChartData:SongChartData = new SongChartData(1.0, [], []);

    if (songData.song.notes.normal != null)
    {
      var songEventsEmpty:Bool = songChartData.getEvents() == null || songChartData.getEvents().length == 0;
      if (songEventsEmpty) songChartData.setEvents(migrateSongEventDataFromLegacy(songData.song.notes.normal));
      songChartData.setNotes(migrateSongNoteDataFromLegacy(songData.song.notes.normal), 'normal');
      songChartData.setScrollSpeed(songData.song.speed.normal, 'normal');
    }
    if (songData.song.notes.easy != null)
    {
      var songEventsEmpty:Bool = songChartData.getEvents() == null || songChartData.getEvents().length == 0;
      if (songEventsEmpty) songChartData.setEvents(migrateSongEventDataFromLegacy(songData.song.notes.easy));
      songChartData.setNotes(migrateSongNoteDataFromLegacy(songData.song.notes.easy), 'easy');
      songChartData.setScrollSpeed(songData.song.speed.easy, 'easy');
    }
    if (songData.song.notes.hard != null)
    {
      var songEventsEmpty:Bool = songChartData.getEvents() == null || songChartData.getEvents().length == 0;
      if (songEventsEmpty) songChartData.setEvents(migrateSongEventDataFromLegacy(songData.song.notes.hard));
      songChartData.setNotes(migrateSongNoteDataFromLegacy(songData.song.notes.hard), 'hard');
      songChartData.setScrollSpeed(songData.song.speed.hard, 'hard');
    }

    return songChartData;
  }

  static function migrateSongNoteDataFromLegacy(sections:Array<LegacyNoteSection>):Array<SongNoteData>
  {
    var songNotes:Array<SongNoteData> = [];

    for (section in sections)
    {
      // Skip empty sections.
      if (section.sectionNotes.length == 0) continue;

      for (note in section.sectionNotes)
      {
        songNotes.push(new SongNoteData(note.time, note.getData(section.mustHitSection), note.length, note.kind));
      }
    }

    return songNotes;
  }

  static function migrateSongEventDataFromLegacy(sections:Array<LegacyNoteSection>):Array<SongEventData>
  {
    var songEvents:Array<SongEventData> = [];

    var lastSectionWasMustHit:Null<Bool> = null;
    for (section in sections)
    {
      // Skip empty sections.
      if (section.sectionNotes.length == 0) continue;

      if (section.mustHitSection != lastSectionWasMustHit)
      {
        lastSectionWasMustHit = section.mustHitSection;

        var firstNote:LegacyNote = section.sectionNotes[0];

        songEvents.push(new SongEventData(firstNote.time, 'FocusCamera', {char: section.mustHitSection ? 0 : 1}));
      }
    }

    return songEvents;
  }
}
