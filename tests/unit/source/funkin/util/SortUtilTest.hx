package funkin.util;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import funkin.data.song.SongData.SongNoteData;
import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.SortUtil;

@:nullSafety
@:access(funkin.util.SortUtil)
class SortUtilTest extends FunkinTest
{
  public function new()
  {
    super();
  }

  @BeforeClass
  public function beforeClass() {}

  @AfterClass
  public function afterClass() {}

  @Before
  public function setup() {}

  @After
  public function tearDown() {}

  @Test
  public function testAlphabetically()
  {
    var arr:Array<String> = ["b", "a", "c"];

    arr.sort(SortUtil.alphabetically);

    Assert.areEqual(["a", "b", "c"], arr);
  }

  @Test
  public function testByZIndex()
  {
    var arr:Array<FlxObject> = [new FlxSprite(), new FlxObject(), new FlxSprite()];

    arr[0].zIndex = 2000;
    arr[1].zIndex = 1000;
    arr[2].zIndex = 3000;

    arr.sort(SortUtil.byZIndex.bind(FlxSort.ASCENDING));

    Assert.areEqual(1000, arr[0].zIndex);
    Assert.areEqual(2000, arr[1].zIndex);
    Assert.areEqual(3000, arr[2].zIndex);

    arr.sort(SortUtil.byZIndex.bind(FlxSort.DESCENDING));

    Assert.areEqual(3000, arr[0].zIndex);
    Assert.areEqual(2000, arr[1].zIndex);
    Assert.areEqual(1000, arr[2].zIndex);
  }
}
