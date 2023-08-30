package funkin.util.tools;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.tools.ArrayTools;

@:nullSafety
@:access(funkin.util.tools.ArrayTools)
class ArrayToolsTest extends FunkinTest
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
  public function testUnique()
  {
    var testArray:Array<Int> = [1, 2, 3, 4, 5, 6, 10, 7, 8, 9, 3, 4, 5, 6, 11, 7, 8];

    var uniqueArray:Array<Int> = ArrayTools.unique(testArray);

    Assert.areEqual(uniqueArray.length, 11);

    // Array order doesn't change
    Assert.areEqual(uniqueArray[0], 1);
    Assert.areEqual(uniqueArray[1], 2);
    Assert.areEqual(uniqueArray[2], 3);
    Assert.areEqual(uniqueArray[3], 4);
    Assert.areEqual(uniqueArray[4], 5);
    Assert.areEqual(uniqueArray[5], 6);
    Assert.areEqual(uniqueArray[6], 10);
    Assert.areEqual(uniqueArray[7], 7);
    Assert.areEqual(uniqueArray[8], 8);
    Assert.areEqual(uniqueArray[9], 9);
    Assert.areEqual(uniqueArray[10], 11);
  }

  @Test
  public function testFind()
  {
    function predicate(a:String):Bool
    {
      return a.startsWith("Hello");
    }

    var testArray:Array<String> = ["Foo", "Bar", "HelloWorld", "Baz", "HelloTest"];

    var result = ArrayTools.find(testArray, predicate);

    Assert.areEqual(result, "HelloWorld");
  }
}
