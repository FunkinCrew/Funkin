package funkin.util;

import flixel.math.FlxPoint;
import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.BezierUtil;

@:nullSafety
@:access(funkin.util.BezierUtil)
class BezierUtilTest extends FunkinTest
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
  public function testBezier2()
  {
    var point1:FlxPoint = FlxPoint.get(1, 1);
    var point2:FlxPoint = FlxPoint.get(2, 2);

    var result:FlxPoint = BezierUtil.bezier2(0.5, point1, point2);

    Assert.areEqual(result.x, 1.5);
    Assert.areEqual(result.y, 1.5);

    result = BezierUtil.bezier2(0.25, point1, point2);

    Assert.areEqual(result.x, 1.25);
    Assert.areEqual(result.y, 1.25);

    result = BezierUtil.bezier2(0.75, point1, point2);

    Assert.areEqual(result.x, 1.75);
    Assert.areEqual(result.y, 1.75);
  }

  @Test
  public function testBezier3()
  {
    var point1:FlxPoint = FlxPoint.get(1, 1);
    var point2:FlxPoint = FlxPoint.get(2, 2);
    var point3:FlxPoint = FlxPoint.get(3, 3);

    var result:FlxPoint = BezierUtil.bezier3(0.5, point1, point2, point3);

    Assert.areEqual(result.x, 2);
    Assert.areEqual(result.y, 2);

    result = BezierUtil.bezier3(0.25, point1, point2, point3);

    Assert.areEqual(result.x, 1.5);
    Assert.areEqual(result.y, 1.5);

    result = BezierUtil.bezier3(0.75, point1, point2, point3);

    Assert.areEqual(result.x, 2.5);
    Assert.areEqual(result.y, 2.5);

    result = BezierUtil.bezier3(0.5, point1, point2, point3);

    Assert.areEqual(result.x, 2);
    Assert.areEqual(result.y, 2);

    result = BezierUtil.bezier3(0.6, point1, point2, point3);

    Assert.areEqual(result.x, 2.2);
    Assert.areEqual(result.y, 2.2);
  }

  @Test
  public function testBezier4()
  {
    var point1:FlxPoint = FlxPoint.get(1, 1);
    var point2:FlxPoint = FlxPoint.get(2, 2);
    var point3:FlxPoint = FlxPoint.get(3, 3);
    var point4:FlxPoint = FlxPoint.get(4, 4);

    var result:FlxPoint = BezierUtil.bezier4(0.5, point1, point2, point3, point4);

    Assert.areEqual(result.x, 2.5);
    Assert.areEqual(result.y, 2.5);

    result = BezierUtil.bezier4(0.25, point1, point2, point3, point4);

    Assert.areEqual(result.x, 1.75);
    Assert.areEqual(result.y, 1.75);

    result = BezierUtil.bezier4(0.75, point1, point2, point3, point4);

    Assert.areEqual(result.x, 3.25);
    Assert.areEqual(result.y, 3.25);
  }

  @Test
  public function testBezier5()
  {
    var point1:FlxPoint = FlxPoint.get(1, 1);
    var point2:FlxPoint = FlxPoint.get(2, 2);
    var point3:FlxPoint = FlxPoint.get(3, 3);
    var point4:FlxPoint = FlxPoint.get(4, 4);
    var point5:FlxPoint = FlxPoint.get(5, 5);

    var result:FlxPoint = BezierUtil.bezier5(0.5, point1, point2, point3, point4, point5);

    Assert.areEqual(result.x, 3);
    Assert.areEqual(result.y, 3);

    result = BezierUtil.bezier5(0.25, point1, point2, point3, point4, point5);

    Assert.areEqual(result.x, 2);
    Assert.areEqual(result.y, 2);

    result = BezierUtil.bezier5(0.75, point1, point2, point3, point4, point5);

    Assert.areEqual(result.x, 4);
    Assert.areEqual(result.y, 4);

    result = BezierUtil.bezier5(0.5, point1, point2, point3, point4, point5);

    Assert.areEqual(result.x, 3);
    Assert.areEqual(result.y, 3);
  }
}
