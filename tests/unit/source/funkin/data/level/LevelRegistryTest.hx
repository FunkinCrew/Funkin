package funkin.data.story.level;

import funkin.data.story.level.LevelRegistry;
import funkin.ui.story.Level;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

@:nullSafety
@:access(funkin.ui.story.Level)
@:access(funkin.data.story.level.LevelRegistry)
class LevelRegistryTest extends FunkinTest
{
  public function new()
  {
    super();
  }

  @BeforeClass
  public function beforeClass():Void
  {
    LevelRegistry.instance.loadEntries();
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
    Assert.isNotNull(LevelRegistry.instance);
  }

  @Test
  public function testParseEntryData():Void
  {
    var result:Null<LevelData> = LevelRegistry.instance.parseEntryData("test");

    Assert.isNotNull(result);

    Assert.areEqual("1.0.0", result.version);
    Assert.areEqual("TEACHING TIME", result.name);
    Assert.areEqual("storymenu/titles/tutorial", result.titleAsset);

    Assert.areEqual(2, result.props.length);

    Assert.areEqual("storymenu/props/gf", result.props[0].assetPath);
    Assert.areEqual(1.0, result.props[0].scale);
    Assert.areEqual(2, result.props[0].danceEvery);
    Assert.areEqual([80, 80], result.props[0].offsets);
    var anims = result.props[0].animations;
    Assert.isNotNull(anims);
    Assert.areEqual(2, anims.length);

    var anim0 = anims[0];
    Assert.isNotNull(anim0);
    Assert.areEqual("danceLeft", anim0.name);
    Assert.areEqual("idle0", anim0.prefix);
    Assert.areEqual([30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], anim0.frameIndices);

    var anim1 = anims[1];
    Assert.isNotNull(anim1);
    Assert.areEqual("danceRight", anim1.name);
    Assert.areEqual("idle0", anim1.prefix);
    Assert.areEqual([15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], anim1.frameIndices);

    Assert.areEqual("storymenu/props/bf", result.props[1].assetPath);
    Assert.areEqual(1.0, result.props[1].scale);
    Assert.areEqual(2, result.props[1].danceEvery);
    Assert.areEqual([150, 80], result.props[1].offsets);
    anims = result.props[1].animations;
    Assert.isNotNull(anims);
    Assert.areEqual(2, anims.length);

    anim0 = anims[0];
    Assert.isNotNull(anim0);
    Assert.areEqual("idle", anim0.name);
    Assert.areEqual("idle0", anim0.prefix);
    Assert.areEqual(24, anim0.frameRate);

    anim1 = anims[1];
    Assert.isNotNull(anim1);
    Assert.areEqual("confirm", anim1.name);
    Assert.areEqual("confirm0", anim1.prefix);
    Assert.areEqual(24, anim1.frameRate);

    Assert.areEqual("#F9CF51", result.background);
    Assert.areEqual(["tutorial"], result.songs);
  }

  @Test
  public function testCreateEntry():Void
  {
    var result:Null<Level> = LevelRegistry.instance.createEntry("test");

    Assert.isNotNull(result);

    Assert.areEqual("Level(test)", result.toString());
    Assert.areEqual("TEACHING TIME", result.getTitle());

    Assert.areEqual(true, result.isUnlocked());
    Assert.areEqual(true, result.isVisible());
  }

  @Test
  public function testFetchEntry():Void
  {
    var result:Null<Level> = LevelRegistry.instance.fetchEntry("test");

    Assert.isNotNull(result);

    Assert.areEqual("Level(test)", result.toString());
    Assert.areEqual("TEACHING TIME", result.getTitle());

    Assert.areEqual(true, result.isUnlocked());
    Assert.areEqual(true, result.isVisible());
  }

  @Test
  public function testCreateEntryBlankPath():Void
  {
    // Using @:jcustomparse, `titleAsset` has a validation function that ensures it is not blank.
    // This test makes sure that the validation function is being called, and that the error
    // results in the level failing to parse.

    FunkinAssert.validateThrows(function() {
      var result:Null<Level> = LevelRegistry.instance.createEntry("blankpathtest");
    }, function(err) {
      return err == "Could not parse level data for id: blankpathtest";
    });
  }

  @Test
  public function testFetchBadEntry():Void
  {
    var result:Null<Level> = LevelRegistry.instance.fetchEntry("blablabla");
    Assert.isNull(result);

    var result2:Null<Level> = LevelRegistry.instance.fetchEntry("blankpathtest");
    Assert.isNull(result2);
  }
}
