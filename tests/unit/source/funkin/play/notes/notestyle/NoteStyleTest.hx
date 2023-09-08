package funkin.play.notes.notestyle;

import flixel.util.FlxSort;
import funkin.util.SortUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.animation.FlxAnimationController;
import openfl.utils.Assets;
import flixel.math.FlxPoint;

@:access(funkin.play.notes.notestyle.NoteStyle)
class NoteStyleTest extends FunkinTest
{
  public function new()
  {
    super();
  }

  @BeforeClass
  public function beforeClass()
  {
    NoteStyleRegistry.instance.loadEntries();
  }

  @AfterClass
  public function afterClass() {}

  @Before
  public function setup() {}

  @After
  public function tearDown() {}

  @Test
  public function testBuildNoteSprite()
  {
    var target:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry("funkin");

    Assert.isNotNull(target);

    // Arrange
    var mockNoteSprite = Mockatoo.mock(NoteSprite);
    var mockAnim = Mockatoo.mock(FlxAnimationController);
    var scale = new FlxPoint(1, 1); // handle sprite.scale.x on the mock

    mockNoteSprite.animation = mockAnim; // Tell the mock to forward calls to the animation controller mock.
    mockNoteSprite.scale.returns(scale); // Redirect this final variable to a local variable.
    mockNoteSprite.antialiasing.callsRealMethod(); // Tell the mock to treat this like a normal property.
    mockNoteSprite.frames.callsRealMethod(); // Tell the mock to treat this like a normal property.

    // Act
    target.buildNoteSprite(mockNoteSprite);

    var expectedGraphic:FlxGraphic = FlxG.bitmap.add("shared:assets/shared/images/arrows.png");

    // Assert
    Assert.isNotNull(mockNoteSprite.frames);
    mockNoteSprite.frames.frames.sort(SortUtil.byFrameName);
    var frameCount:Int = mockNoteSprite.frames.frames.length;
    Assert.areEqual(24, frameCount);

    // Validate each frame.
    for (i in 0...frameCount)
    {
      var currentFrame:FlxFrame = mockNoteSprite.frames.frames[i];
      switch (i)
      {
        case 0:
          Assert.areEqual("confirmDown0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 1:
          Assert.areEqual("confirmDown0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 2:
          Assert.areEqual("confirmLeft0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 3:
          Assert.areEqual("confirmLeft0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 4:
          Assert.areEqual("confirmRight0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 5:
          Assert.areEqual("confirmRight0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 6:
          Assert.areEqual("confirmUp0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 7:
          Assert.areEqual("confirmUp0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 8:
          Assert.areEqual("noteDown0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 9:
          Assert.areEqual("noteLeft0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 10:
          Assert.areEqual("noteRight0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 11:
          Assert.areEqual("noteUp0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 12:
          Assert.areEqual("pressedDown0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 13:
          Assert.areEqual("pressedDown0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 14:
          Assert.areEqual("pressedLeft0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 15:
          Assert.areEqual("pressedLeft0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 16:
          Assert.areEqual("pressedRight0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 17:
          Assert.areEqual("pressedRight0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 18:
          Assert.areEqual("pressedUp0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 19:
          Assert.areEqual("pressedUp0002", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 20:
          Assert.areEqual("staticDown0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 21:
          Assert.areEqual("staticLeft0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 22:
          Assert.areEqual("staticRight0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        case 23:
          Assert.areEqual("staticUp0001", currentFrame.name);
          Assert.areEqual(expectedGraphic, currentFrame.parent);
        default:
          Assert.fail('Got unexpected frame number ${i}');
      }
    }

    // Verify animations were applied.
    @:privateAccess {
      mockAnim.addByPrefix('purpleScroll', 'noteLeft', 24, false, false, false).verify(times(1));
      mockAnim.addByPrefix('blueScroll', 'noteDown', 24, false, false, false).verify(times(1));
      mockAnim.addByPrefix('greenScroll', 'noteUp', 24, false, false, false).verify(times(1));
      mockAnim.addByPrefix('redScroll', 'noteRight', 24, false, false, false).verify(times(1));
      mockAnim.destroyAnimations().verify(times(1));
      mockAnim.set_frameIndex(0).verify(times(1));
      // Verify there were no other functions called.
      mockAnim.verifyZeroInteractions();
    }

    // Verify sprite was initialized.
    @:privateAccess {
      mockNoteSprite.set_graphic(expectedGraphic).verify(times(1));
      mockNoteSprite.graphicLoaded().verify(times(1));
      mockNoteSprite.set_antialiasing(true).verify(times(1));
      mockNoteSprite.set_frames(mockNoteSprite.frames).verify(times(1));
      mockNoteSprite.set_frame(mockNoteSprite.frames.frames[21]).verify(times(1));
      mockNoteSprite.resetHelpers().verify(times(1));

      Assert.areEqual(1, mockNoteSprite.scale.x);
      Assert.areEqual(1, mockNoteSprite.scale.y);
      // Verify there were no other functions called.
      mockNoteSprite.verifyZeroInteractions();
    }
  }

  @Test
  public function testFallbackBehavior()
  {
    var target1:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry("funkin");
    var target2:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry("test2");

    Assert.isNotNull(target1);
    Assert.isNotNull(target2);

    Assert.areEqual("funkin", target1.id);
    Assert.areEqual("test2", target2.id);

    Assert.areEqual("Funkin'", target1.getName());
    Assert.areEqual("Test2", target2.getName());

    Assert.isNull(target1.getFallbackID());
    Assert.areEqual(target1.id, target2.getFallbackID());

    // Overridden fields are different.
    Assert.areEqual("arrows", target1.getNoteAssetPath(false));
    Assert.areEqual("coolstuff", target2.getNoteAssetPath(false));
    Assert.areEqual("shared:arrows", target1.getNoteAssetPath(true));
    Assert.areEqual("shared:coolstuff", target2.getNoteAssetPath(true));

    // Unspecified fields use the fallback.
    // Should NOT return null!
    Assert.areEqual("assets/images/NOTE_hold_assets.png", target1.getHoldNoteAssetPath(false));
    Assert.areEqual("assets/images/NOTE_hold_assets.png", target2.getHoldNoteAssetPath(false));

    Assert.areEqual("NOTE_hold_assets", target1.getHoldNoteAssetPath(true));
  }
}
