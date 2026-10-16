package funkin.modding.psych;

#if sys
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.importer.FNFLegacyData;
import funkin.data.song.importer.FNFLegacyImporter;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import haxe.Json;
#end

typedef PsychSongJson =
{
  metadata:String,
  chart:String
}

/**
 * Fase 2.2 y 2.4: canciones de Psych Engine (data/<cancion>/<cancion>-<dificultad>.json).
 * Convierte el chart (notas, dificultades, stage, personajes y eventos) a los JSON de QT Slice en memoria.
 * SongRegistry usa estos datos solo si el mod no trae sus propios archivos de QT Slice.
 */
class PsychSongAdapter
{
  static final DIFFICULTIES:Array<String> = ['easy', 'normal', 'hard'];

  /** id de canción -> carpeta data/<cancion> del mod donde está. */
  static var songDirs:Map<String, String> = new Map();

  static var cache:Map<String, PsychSongJson> = new Map();

  /**
   * Busca canciones de Psych en las carpetas data/ de los mods habilitados.
   * @return Los ids de canción encontrados.
   */
  public static function listSongIds():Array<String>
  {
    #if sys
    songDirs = new Map();
    cache = new Map();

    for (modDir in Save.instance.enabledModDirs.value)
    {
      var dataDir:String = PolymodHandler.MOD_FOLDER + '/' + modDir + '/data';
      if (!sys.FileSystem.exists(dataDir) || !sys.FileSystem.isDirectory(dataDir)) continue;

      for (song in sys.FileSystem.readDirectory(dataDir))
      {
        var songDir:String = dataDir + '/' + song;
        if (!sys.FileSystem.isDirectory(songDir)) continue;
        if (!hasPsychChart(songDir, song)) continue;
        if (!songDirs.exists(song)) songDirs.set(song, songDir);
      }
    }

    var ids:Array<String> = [];
    for (id in songDirs.keys()) ids.push(id);
    if (ids.length > 0) trace('[PSYCH] Canciones de Psych encontradas: ' + ids.join(', '));
    return ids;
    #else
    return [];
    #end
  }

  /** JSON de metadatos de QT para una canción de Psych, o null si no es de Psych. */
  public static function metadataJson(id:String):Null<String>
  {
    #if sys
    var converted:Null<PsychSongJson> = convert(id);
    return converted == null ? null : converted.metadata;
    #else
    return null;
    #end
  }

  /** JSON de chart de QT para una canción de Psych, o null si no es de Psych. */
  public static function chartJson(id:String):Null<String>
  {
    #if sys
    var converted:Null<PsychSongJson> = convert(id);
    return converted == null ? null : converted.chart;
    #else
    return null;
    #end
  }

  #if sys
  static function hasPsychChart(songDir:String, song:String):Bool
  {
    for (diff in DIFFICULTIES)
    {
      if (sys.FileSystem.exists(songDir + '/' + song + '-' + diff + '.json')) return true;
    }
    return sys.FileSystem.exists(songDir + '/' + song + '.json');
  }

  static function convert(id:String):Null<PsychSongJson>
  {
    if (cache.exists(id)) return cache.get(id);

    var songDir:Null<String> = songDirs.get(id);
    if (songDir == null) return null;

    // Psych guarda un archivo por dificultad. Se leen por separado y se unen.
    var charts:Array<{diff:String, data:FNFLegacyData, raw:Dynamic}> = [];
    for (diff in DIFFICULTIES)
    {
      var path:String = songDir + '/' + id + '-' + diff + '.json';
      if (!sys.FileSystem.exists(path)) continue;
      loadChart(path, diff, charts);
    }
    if (charts.length == 0)
    {
      var path:String = songDir + '/' + id + '.json';
      if (sys.FileSystem.exists(path)) loadChart(path, 'normal', charts);
    }
    if (charts.length == 0) return null;

    var first = charts[0];
    var rawSong:Dynamic = first.raw.song;

    var metadata:SongMetadata = FNFLegacyImporter.migrateMetadata(first.data, first.diff);
    metadata.playData.difficulties = [for (c in charts) c.diff];
    metadata.playData.stage = rawSong.stage ?? metadata.playData.stage;
    metadata.playData.characters = new SongCharacterData(rawSong.player1 ?? 'bf', rawSong.gfVersion ?? 'gf', rawSong.player2 ?? 'dad');

    var chart:SongChartData = FNFLegacyImporter.migrateChartData(first.data, first.diff);
    for (i in 1...charts.length)
    {
      var other:SongChartData = FNFLegacyImporter.migrateChartData(charts[i].data, charts[i].diff);
      for (diff in other.notes.keys()) chart.notes.set(diff, other.notes.get(diff));
      for (diff in other.scrollSpeed.keys()) chart.scrollSpeed.set(diff, other.scrollSpeed.get(diff));
    }

    // Eventos de Psych (fase 2.4). Los que son de Lua se omiten por ahora.
    var psychEvents:Null<Array<Dynamic>> = rawSong.events;
    if (psychEvents != null) chart.events = PsychEventAdapter.convert(psychEvents, id);

    var result:PsychSongJson = {metadata: metadata.serialize(), chart: chart.serialize()};
    cache.set(id, result);
    trace('[PSYCH] Chart convertido: ' + id + ' (' + charts.length + ' dificultad(es))');
    return result;
  }

  static function loadChart(path:String, diff:String, charts:Array<{diff:String, data:FNFLegacyData, raw:Dynamic}>):Void
  {
    var text:String = sys.io.File.getContent(path);
    var data:Null<FNFLegacyData> = FNFLegacyImporter.parseLegacyDataRaw(text, path);
    if (data != null) charts.push({diff: diff, data: data, raw: Json.parse(text)});
  }
  #end
}
