package funkin.data.song;

import funkin.data.song.SongData;
import funkin.data.song.SongRegistry;
import funkin.play.song.Song;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

@:nullSafety
@:access(funkin.play.song.Song)
@:access(funkin.data.song.SongRegistry)
class SongRegistryTest extends FunkinTest
{
  public function new()
  {
    super();
  }

  @BeforeClass
  public function beforeClass():Void
  {
    FunkinAssert.initAssertTrace();
    SongRegistry.instance.loadEntries();
  }

  @AfterClass
  public function afterClass():Void {}

  @Before
  public function setup():Void {}

  @After
  public function tearDown():Void {}

  @Test
  public function testValid():Void
  {
    Assert.isNotNull(SongRegistry.instance);
  }

  @Test
  public function testParseMetadata():Void
  {
    var result:Null<SongData.SongMetadata> = SongRegistry.instance.parseEntryMetadata("bopeebo");

    Assert.isNotNull(result);

    var expectedVersion:thx.semver.Version = "2.0.0";
    Assert.areEqual(expectedVersion, result.version);
    Assert.areEqual("Bopeebo", result.songName);
    Assert.areEqual("Kawai Sprite", result.artist);
    Assert.areEqual(SongData.SongTimeFormat.MILLISECONDS, result.timeFormat);
    Assert.areEqual("MasterEric (by hand)", result.generatedBy);
  }

  @Test
  public function testParseChartData():Void
  {
    var result:Null<SongData.SongChartData> = SongRegistry.instance.parseEntryChartData("bopeebo");

    Assert.isNotNull(result);

    var expectedVersion:thx.semver.Version = "2.0.0";
    Assert.areEqual(expectedVersion, result.version);
  }

  /**
   * A test validating an error is thrown when attempting to parse chart data as metadata.
   */
  @Test
  public function testParseMetadataSwapped():Void
  {
    // Arrange
    FunkinAssert.clearTraces();

    // Act
    var result:Null<SongData.SongMetadata> = SongRegistry.instance.parseEntryMetadata("bopeebo-swapped");

    // Assert
    Assert.isNull(result);
    FunkinAssert.assertTrace("[SONG] Failed to parse entry data: bopeebo-swapped");
    FunkinAssert.assertTrace("  Unknown variable \"scrollSpeed\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:3");
    FunkinAssert.assertTrace("  Unknown variable \"events\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:7");
    FunkinAssert.assertTrace("  Unknown variable \"notes\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:185");
    FunkinAssert.assertTrace("  Uninitialized variable \"songName\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:1738");
    FunkinAssert.assertTrace("  Uninitialized variable \"timeFormat\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:1738");
    FunkinAssert.assertTrace("  Uninitialized variable \"timeChanges\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:1738");
    FunkinAssert.assertTrace("  Uninitialized variable \"playData\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:1738");
    FunkinAssert.assertTrace("  Uninitialized variable \"artist\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-metadata.json:1738");
  }

  /**
   * A test validating an error is thrown when attempting to parse metadata as chart data.
   */
  @Test
  public function testParseChartDataSwapped():Void
  {
    // Arrange
    FunkinAssert.clearTraces();

    // Act
    var result:Null<SongData.SongChartData> = SongRegistry.instance.parseEntryChartData("bopeebo-swapped");

    // Assert
    Assert.isNull(result);
    FunkinAssert.assertTrace("[SONG] Failed to parse entry data: bopeebo-swapped");
    FunkinAssert.assertTrace("  Unknown variable \"songName\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:3");
    FunkinAssert.assertTrace("  Unknown variable \"artist\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:4");
    FunkinAssert.assertTrace("  Unknown variable \"timeFormat\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:5");
    FunkinAssert.assertTrace("  Unknown variable \"timeChanges\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:6");
    FunkinAssert.assertTrace("  Unknown variable \"playData\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:7");
    FunkinAssert.assertTrace("  Uninitialized variable \"notes\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:15");
    FunkinAssert.assertTrace("  Uninitialized variable \"events\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:15");
    FunkinAssert.assertTrace("  Uninitialized variable \"scrollSpeed\"");
    FunkinAssert.assertTrace("    at assets/data/songs/bopeebo-swapped/bopeebo-swapped-chart.json:15");
  }
}
