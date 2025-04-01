package funkin.util;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.DateUtil;

@:nullSafety
@:access(funkin.util.DateUtil)
class DateUtilTest extends FunkinTest
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
  public function testGenerateTimestamp()
  {
    var date:Date = new Date(2020, 10 - 1, 31, 3, 0, 0);
    var timestamp:String = DateUtil.generateTimestamp(date);
    Assert.areEqual("2020-10-31-03-00-00", timestamp);
  }
}
