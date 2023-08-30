package funkin.play.notes.notestyle;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.animation.FlxAnimationController;

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
  @Ignore("This test doesn't work, crashes when the project has 2 mocks of the same class???")
  public function testBuildNoteSprite()
  {
    var target:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry("funkin");

    Assert.isNotNull(target);

    var mockNoteSprite:NoteSprite = mock(NoteSprite);
    // var mockAnim = mock(FlxAnimationController);
    // mockNoteSprite.animation = mockAnim;

    target.buildNoteSprite(mockNoteSprite);

    Assert.areEqual(mockNoteSprite.frames, []);
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
