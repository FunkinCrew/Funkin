package funkin.util.assets;

import funkin.util.assets.FlxAnimationUtil;
import flixel.animation.FlxAnimationController;
import funkin.data.animation.AnimationData;
import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.DateUtil;
import flixel.FlxSprite;

@:nullSafety
@:access(funkin.util.assets.FlxAnimationUtil)
class FlxAnimationUtilTest extends FunkinTest
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
  public function testAddAtlasAnimation()
  {
    // Build a mock child class of FlxSprite
    var mockSprite = Mockatoo.mock(FlxSprite);
    var mockAnim = Mockatoo.mock(FlxAnimationController);
    mockSprite.animation = mockAnim;

    var animData:AnimationData =
      {
        name: "testAnim",
        prefix: "blablabla"
      };

    FlxAnimationUtil.addAtlasAnimation(mockSprite, animData);

    // Verify that the method was called once.
    // If not, a VerificationException will be thrown and the test will fail.
    mockAnim.addByPrefix("testAnim", "blablabla", 24, false, false, false).verify(times(1));

    // Verify there were no other functions called.
    mockAnim.verifyZeroInteractions();
    mockSprite.verifyZeroInteractions();

    var animData2:AnimationData =
      {
        name: "testAnim2",
        prefix: "blablabla2",
        frameIndices: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        frameRate: 12,
        flipX: true,
        flipY: true,
        looped: true
      };

    FlxAnimationUtil.addAtlasAnimation(mockSprite, animData2);

    try
    {
      mockAnim.addByIndices("testAnim2", "blablabla2", cast anyIterator, "", 12, true, true, true).verify(times(1));
    }
    catch (e)
    {
      trace('CAUGHT EXCEPTION');
      trace(e);
    }

    mockAnim.verifyZeroInteractions();
    mockSprite.verifyZeroInteractions();
  }

  @Test
  public function testAddAtlasAnimations()
  {
    // Build a mock child class of FlxSprite
    var mockSprite = Mockatoo.mock(FlxSprite);
    var mockAnim = Mockatoo.mock(FlxAnimationController);
    mockSprite.animation = mockAnim;

    var animData:Array<AnimationData> = [
      {
        name: "testAnim",
        prefix: "blablabla"
      },
      {
        name: "testAnim2",
        prefix: "blablabla2"
      },
      {
        name: "testAnim3",
        prefix: "blablabla3"
      }
    ];

    FlxAnimationUtil.addAtlasAnimations(mockSprite, animData);

    // Verify that the method was called once.
    // If not, a VerificationException will be thrown and the test will fail.
    mockAnim.addByPrefix("testAnim", "blablabla", 24, false, false, false).verify(times(1));
    mockAnim.addByPrefix("testAnim2", "blablabla2", 24, false, false, false).verify(times(1));
    mockAnim.addByPrefix("testAnim3", "blablabla3", 24, false, false, false).verify(times(1));

    // Verify there were no other functions called.
    mockAnim.verifyZeroInteractions();
    mockSprite.verifyZeroInteractions();
  }
}
