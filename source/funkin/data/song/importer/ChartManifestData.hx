package funkin.data.song.importer;

/**
 * A helper JSON blob found in `.fnfc` files.
 */
class ChartManifestData
{
  /**
   * The current semantic version of the chart manifest data.
   */
  public static final CHART_MANIFEST_DATA_VERSION:thx.semver.Version = "1.0.0";

  @:default(funkin.data.song.importer.ChartManifestData.CHART_MANIFEST_DATA_VERSION)
  @:jcustomparse(funkin.data.DataParse.semverVersion)
  @:jcustomwrite(funkin.data.DataWrite.semverVersion)
  public var version:thx.semver.Version;

  /**
   * The internal song ID for this chart.
   * The metadata and chart data file names are derived from this.
   */
  public var songId:String;

  public function new(songId:String)
  {
    this.version = CHART_MANIFEST_DATA_VERSION;
    this.songId = songId;
  }

  public function getMetadataFileName(?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    return '$songId-metadata${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.${Constants.EXT_DATA}';
  }

  public function getChartDataFileName(?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    return '$songId-chart${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.${Constants.EXT_DATA}';
  }

  public function getInstFileName(?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    return 'Inst${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.${Constants.EXT_SOUND}';
  }

  public function getVocalsFileName(charId:String, ?variation:String):String
  {
    if (variation == null || variation == '') variation = Constants.DEFAULT_VARIATION;

    return 'Voices-$charId${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.${Constants.EXT_SOUND}';
  }

  /**
   * Serialize this ChartManifestData into a JSON string.
   * @return The JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var writer = new json2object.JsonWriter<ChartManifestData>();
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.version = CHART_MANIFEST_DATA_VERSION;
  }

  public static function deserialize(contents:String):Null<ChartManifestData>
  {
    var parser = new json2object.JsonParser<ChartManifestData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, 'manifest.json');

    if (parser.errors.length > 0)
    {
      trace('[ChartManifest] Failed to parse chart file manifest');

      for (error in parser.errors)
        DataError.printError(error);

      return null;
    }
    return parser.value;
  }
}
