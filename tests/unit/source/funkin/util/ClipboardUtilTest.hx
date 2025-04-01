package funkin.util;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.ClipboardUtil;

@:nullSafety
@:access(funkin.util.ClipboardUtil)
class ClipboardUtilTest extends FunkinTest
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
  public function testGetSetClipboard()
  {
    var testString = "test string";
    ClipboardUtil.setClipboard(testString);
    var clipboardString = ClipboardUtil.getClipboard();
    Assert.areEqual(testString, clipboardString);
  }

  @Ignore("This test doesn't work, Lime issue?")
  @Test
  public function testAddRemoveListener()
  {
    ClipboardUtil.addListener(onClipboardChange);

    var testString = "test string";
    ClipboardUtil.setClipboard(testString);

    var clipboardString = ClipboardUtil.getClipboard();
    Assert.areEqual(testString, clipboardString);

    step();

    // TODO: Fix issue where this test fails
    Assert.areEqual(1, count);

    ClipboardUtil.removeListener(onClipboardChange);

    var testString2 = "test string 2";
    ClipboardUtil.setClipboard(testString2);

    var clipboardString2 = ClipboardUtil.getClipboard();
    Assert.areEqual(testString2, clipboardString2);

    Assert.areEqual(1, count);
  }

  var count:Int = 0;

  function onClipboardChange()
  {
    count += 1;
  }
}
