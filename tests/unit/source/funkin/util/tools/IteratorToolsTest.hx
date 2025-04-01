package funkin.util.tools;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.tools.IteratorTools;

@:nullSafety
@:access(funkin.util.tools.IteratorTools)
class IteratorToolsTest extends FunkinTest
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
  public function testArray()
  {
    var iter = new MyStringIterator("HelloWorld");

    var arr = IteratorTools.array(iter);

    Assert.areEqual(["H", "e", "l", "l", "o", "W", "o", "r", "l", "d"], arr);
  }
}

class MyStringIterator
{
  var s:String;
  var i:Int;

  public function new(s:String)
  {
    this.s = s;
    i = 0;
  }

  public function hasNext()
  {
    return i < s.length;
  }

  public function next()
  {
    return s.charAt(i++);
  }
}
