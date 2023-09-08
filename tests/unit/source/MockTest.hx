package;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.DateUtil;

@:nullSafety
class MockTest extends FunkinTest
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
  public function testMock()
  {
    // Test that mocking works.

    var mockSprite = Mockatoo.mock(flixel.FlxSprite);
    var mockAnim = Mockatoo.mock(flixel.animation.FlxAnimationController);
    mockSprite.animation = mockAnim;

    var animData:funkin.data.animation.AnimationData =
      {
        name: "testAnim",
        prefix: "blablabla"
      };

    mockSprite.animation.addByPrefix("testAnim", "blablabla", 24, false, false, false);

    // Verify that the method was called once.
    // If not, a VerificationException will be thrown and the test will fail.
    mockAnim.addByPrefix("testAnim", "blablabla", 24, false, false, false).verify(times(1));

    FunkinAssert.validateThrows(function() {
      // Attempt to verify the method was called.
      // This should FAIL, since we didn't call the method.
      mockAnim.addByPrefix("testAnim", "blablabla", 24, false, false, false).verify(times(1));
    }, function(err) {
      return Std.isOfType(err, mockatoo.exception.VerificationException);
    });
  }
}
