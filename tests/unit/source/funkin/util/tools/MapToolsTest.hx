package funkin.util.tools;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.tools.MapTools;

@:nullSafety
@:access(funkin.util.tools.MapTools)
class MapToolsTest extends FunkinTest
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
  public function testSize()
  {
    var testMap:Map<String, String> = ["key1" => "value1", "key2" => "value2", "key3" => "value3"];

    Assert.areEqual(3, MapTools.size(testMap));
  }

  @Test
  public function testValues()
  {
    var testMap:Map<String, String> = ["key1" => "value1", "key2" => "value2", "key3" => "value3"];

    var result:Array<String> = MapTools.values(testMap);
    result.sort(SortUtil.alphabetically);
    Assert.areEqual(["value1", "value2", "value3"], result);
  }

  @Test
  public function testKeyValues()
  {
    var testMap:Map<String, String> = ["key1" => "value1", "key2" => "value2", "key3" => "value3"];

    var result:Array<String> = MapTools.keyValues(testMap);
    result.sort(SortUtil.alphabetically);
    Assert.areEqual(["key1", "key2", "key3"], result);
  }
}
