package funkin.data.notestyle;

import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

@:nullSafety
@:access(funkin.play.notes.notestyle.NoteStyle)
@:access(funkin.data.notestyle.NoteStyleRegistry)
class NoteStyleRegistryTest extends FunkinTest
{
  public function new()
  {
    super();
  }

  @BeforeClass
  public function beforeClass():Void
  {
    NoteStyleRegistry.instance.loadEntries();
  }

  @AfterClass
  public function afterClass():Void {}

  @Before
  public function setup():Void {}

  @After
  public function tearDown():Void {}

  @Test
  public function testValid():Void
  {
    Assert.isNotNull(NoteStyleRegistry.instance);
  }

  @Test
  public function testParseEntryData():Void
  {
    var result:Null<NoteStyleData> = NoteStyleRegistry.instance.parseEntryData("test2");

    Assert.isNotNull(result);

    Assert.areEqual(result.version, "1.0.0");
    Assert.areEqual(result.name, "Test2");
    Assert.areEqual(result.author, "Eric");
    Assert.areEqual(result.fallback, "funkin");

    Assert.isNotNull(result.assets);

    var note:Null<NoteStyleData.NoteStyleAssetData<NoteStyleData.NoteStyleData_Note>> = result.assets.note;
    Assert.isNotNull(note);

    Assert.areEqual(note.assetPath, "shared:coolstuff");
    Assert.areEqual(note.scale, 1.8);
    Assert.areEqual(note.data.left.prefix, "noteLeft1");
    Assert.areEqual(note.data.down.prefix, "noteDown3");
    Assert.areEqual(note.data.up.prefix, "noteUp2");
    Assert.areEqual(note.data.right.prefix, "noteRight4");
  }

  @Test
  public function testFetchEntry():Void
  {
    var result:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry("test2");

    Assert.isNotNull(result);

    Assert.areEqual(result.toString(), "NoteStyle(test2)");
    Assert.areEqual(result.getName(), "Test2");
    Assert.areEqual(result.getAuthor(), "Eric");
    Assert.areEqual(result.getFallbackID(), "funkin");
  }

  @Test
  public function testFetchBadEntry():Void
  {
    var result:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry("blablabla");

    Assert.isNull(result);
  }

  @Test
  public function testFetchDefault():Void
  {
    var nsrMock = Mockatoo.mock(NoteStyleRegistry);

    nsrMock.fetchDefault().callsRealMethod();

    // Perform the call.
    nsrMock.fetchDefault();

    // Verify the underlying call.

    nsrMock.fetchEntry(Constants.DEFAULT_NOTE_STYLE).verify(times(1));
  }
}
