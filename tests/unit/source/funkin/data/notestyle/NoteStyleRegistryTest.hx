package funkin.data.notestyle;

import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

@:access(funkin.play.notes.notestyle.NoteStyle)
@:access(funkin.data.notestyle.NoteStyleRegistry)
class NoteStyleRegistryTest extends FunkinTest
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
  public function testValid()
  {
    Assert.isNotNull(NoteStyleRegistry.instance);
  }

  @Test
  public function testParseEntryData()
  {
    var result:NoteStyleData = NoteStyleRegistry.instance.parseEntryData("test2");

    Assert.areEqual(result.version, "1.0.0");
    Assert.areEqual(result.name, "Test2");
    Assert.areEqual(result.author, "Eric");
    Assert.areEqual(result.fallback, "funkin");

    Assert.areEqual(result.assets.note.assetPath, "shared:coolstuff");
    Assert.areEqual(result.assets.note.scale, 1.8);
    Assert.areEqual(result.assets.note.data.left.prefix, "noteLeft1");
    Assert.areEqual(result.assets.note.data.down.prefix, "noteDown3");
    Assert.areEqual(result.assets.note.data.up.prefix, "noteUp2");
    Assert.areEqual(result.assets.note.data.right.prefix, "noteRight4");
  }

  @Test
  public function testFetchEntry()
  {
    var result:NoteStyle = NoteStyleRegistry.instance.fetchEntry("test2");

    Assert.areEqual(result.toString(), "NoteStyle(test2)");
    Assert.areEqual(result.getName(), "Test2");
    Assert.areEqual(result.getAuthor(), "Eric");
    Assert.areEqual(result.getFallbackID(), "funkin");
  }

  @Test
  public function testFetchBadEntry()
  {
    var result:NoteStyle = NoteStyleRegistry.instance.fetchEntry("blablabla");

    Assert.areEqual(result, null);
  }

  @Test
  public function testFetchDefault()
  {
    var nsrMock:NoteStyleRegistry = mock(NoteStyleRegistry);

    nsrMock.fetchDefault().callsRealMethod();

    // Perform the call.
    nsrMock.fetchDefault();

    // Verify the underlying call.

    nsrMock.fetchEntry(NoteStyleRegistry.DEFAULT_NOTE_STYLE_ID).verify(times(1));
  }
}
