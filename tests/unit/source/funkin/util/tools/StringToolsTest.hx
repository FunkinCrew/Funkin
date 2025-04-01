package funkin.util.tools;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.tools.StringTools;

@:nullSafety
@:access(funkin.util.tools.StringTools)
class StringToolsTest extends FunkinTest
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
  public function testToTitleCase()
  {
    var input = "hello world";

    Assert.areEqual("Hello World", StringTools.toTitleCase(input));
  }

  @Test
  public function testToLowerKebabCase()
  {
    var input = "hello world";

    Assert.areEqual("hello-world", StringTools.toLowerKebabCase(input));
  }

  @Test
  public function testToUpperKebabCase()
  {
    var input = "hello world";

    Assert.areEqual("HELLO-WORLD", StringTools.toUpperKebabCase(input));
  }

  @Test
  public function testParseJSON()
  {
    var input = "{ \"hello\": \"world\" }";

    Assert.areEqual({hello: "world"}, StringTools.parseJSON(input));
  }
}
