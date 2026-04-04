package funkin.data.song.importer;

/**
 * A helper JSON blob found in `.fnfc` files.
 */
class ChartManifestData
{
  /**
   * The current semantic version of the chart manifest data.
   */
  public static final CHART_MANIFEST_DATA_VERSION:thx.semver.Version = '1.0.0';

  /**
   * A regex pattern to match invalid characters in song IDs for sanitization.
   */
  public static final INVALID_ID_REGEX:EReg = ~/[\/\\:*?"<>|]/g;

  /**
   * The semantic version of this chart manifest data.
   * Used for compatibility checks when loading from JSON.
   */
  @:jcustomparse(funkin.data.DataParse.semverVersion) @:jcustomwrite(funkin.data.DataWrite.semverVersion)
  public var version:thx.semver.Version;

  /**
   * The internal song ID for this chart.
   * The metadata and chart data file names are derived from this.
   */
  public var songId(default, set):String;

  function set_songId(value:String):String
  {
    songId = INVALID_ID_REGEX.replace(value.trim(), '');
    return songId;
  }

  public function new(songId:String)
  {
    this.version = CHART_MANIFEST_DATA_VERSION;
    this.songId = songId;
  }

  /**
   * Determine the relative filename of the chart metadata file for a given variation.
   * @param variation The song variation, if any.
   * @return The expected file name.
   */
  public function getMetadataFileName(?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    return '$songId-metadata${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.${Constants.EXT_DATA}';
  }

  /**
   * Determine the relative filename of the chart data file for a given variation.
   * @param variation The song variation, if any.
   * @return The expected file name.
   */
  public function getChartDataFileName(?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    return '$songId-chart${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.${Constants.EXT_DATA}';
  }

  /**
   * Get the expected file name for the character's vocal track for a given variation.
   * @param charId The character vocal ID. Make sure to get this from `playData.characters.instrumental`!
   * @param variation The song variation, if any.
   * @return The expected file name.
   */
  public function getInstFileName(?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    var instId:String = variation == Constants.DEFAULT_VARIATION ? '' : '-$variation';
    // Get the file name as it would be in the assets folder.
    return funkin.assets.Paths.inst(this.songId, instId, false).fileName;
  }

  /**
   * Get the expected file name for the character's vocal track for a given variation.
   * @param charId The character vocal ID. Make sure to get this from `playData.characters.playerVocals` or `playData.characters.opponentVocals`!
   * @param variation The song variation, if any.
   * @return The expected file name.
   */
  public function getVocalsFileName(charId:String, ?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    var vocalId:String = variation == Constants.DEFAULT_VARIATION ? '-$charId' : '-$charId-$variation';
    // Get the file name as it would be in the assets folder.
    return funkin.assets.Paths.voices(this.songId, vocalId, false).fileName;
  }

  /**
   * Serialize this ChartManifestData into a JSON string.
   *
   * @param pretty Whether to format the JSON with indentation and newlines.
   * @return The JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var writer = new json2object.JsonWriter<ChartManifestData>();
    return writer.write(this, pretty ? ' ' : null);
  }

  function updateVersionToLatest():Void
  {
    this.version = CHART_MANIFEST_DATA_VERSION;
  }

  /**
   * Parse a JSON-serialized ChartManifestData from a string.
   * @param contents The JSON string to parse.
   * @return The deserialized ChartManifestData, or `null` if parsing failed.
   */
  public static function deserialize(contents:String):Null<ChartManifestData>
  {
    var parser = new json2object.JsonParser<ChartManifestData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, 'manifest.json');

    if (parser.errors.length > 0)
    {
      trace('[ChartManifest] Failed to parse chart file manifest');

      for (error in parser.errors) DataError.printError(error);

      return null;
    }
    return parser.value;
  }
}
