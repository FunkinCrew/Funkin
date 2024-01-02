package funkin.data;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.data.BaseRegistry;
import funkin.util.SortUtil;
import funkin.util.VersionUtil;

@:nullSafety
@:access(funkin.data.BaseRegistry)
class BaseRegistryTest extends FunkinTest
{
  public function new()
  {
    super();
  }

  @BeforeClass
  public function beforeClass()
  {
    FunkinAssert.initAssertTrace();
  }

  @AfterClass
  public function afterClass() {}

  @Before
  public function setup() {}

  @After
  public function tearDown() {}

  @Test
  public function testMyTypeRegistry()
  {
    // This shouldn't crash.
    MyTypeRegistry.instance.loadEntries();

    // Ensure all entries were loaded.
    var entryList = MyTypeRegistry.instance.listEntryIds();
    entryList.sort(SortUtil.alphabetically);

    Assert.areEqual(entryList, [
      "blablabla",
      "fizzbuzz",
      "foobar",
      // "junk"
    ]);

    // Ensure this one is not in the list.
    Assert.areEqual(entryList.indexOf("junk"), -1);

    // Ensure blablabla got parsed correctly.
    var blablabla = MyTypeRegistry.instance.fetchEntry("blablabla");
    Assert.isNotNull(blablabla);
    Assert.areEqual(blablabla.id, "blablabla");
    Assert.areEqual(blablabla._data.version, "1.0.0");
    Assert.areEqual(blablabla._data.name, "blablabla API");
  }
}

typedef MyTypeData =
{
  /**
   * The version number of the data schema.
   * When making changes to the note style data format, this should be incremented,
   * and a migration function should be added to handle old versions.
   */
  @:default(funkin.data.BaseRegistryTest.MyTypeRegistry.DATA_VERSION)
  var version:String;

  var id:String;
  var name:String;
  var data:Array<MySubTypeData>;
}

typedef MySubTypeData =
{
  var foo:String;
  var bar:String;
};

typedef MyTypeData_v0_1_x =
{
  var version:String;
  var id:Int;
  var name:String;
};

class MyType implements IRegistryEntry<MyTypeData>
{
  /**
   * The ID of the mytype.
   */
  public final id:String;

  /**
   * Mytype data as parsed from the JSON file.
   */
  public final _data:MyTypeData;

  /**
   * @param id The ID of the JSON file to parse.
   */
  public function new(id:String)
  {
    this.id = id;
    _data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse mytype data for id: $id';
    }
  }

  public function destroy():Void {}

  public function toString():String
  {
    return 'MyType($id)';
  }

  static function _fetchData(id:String):Null<MyTypeData>
  {
    return MyTypeRegistry.instance.parseEntryDataWithMigration(id, MyTypeRegistry.instance.fetchEntryVersion(id));
  }

  public function getSubData():Array<MySubTypeData>
  {
    return _data.data;
  }
}

class MyTypeRegistry extends BaseRegistry<MyType, MyTypeData>
{
  /**
   * The current version string for the note style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateMyTypeData()` function.
   */
  public static final DATA_VERSION:String = "1.0.0";

  public static final instance:MyTypeRegistry = new MyTypeRegistry();

  public function new()
  {
    super('MYTYPE', 'mytype');
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<MyTypeData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<MyTypeData>();
    parser.ignoreUnknownVariables = false;

    switch (loadEntryFile(id))
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, id);
      return null;
    }
    return parser.value;
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData_v0_1_x(id:String):Null<MyTypeData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<MyTypeData_v0_1_x>();
    parser.ignoreUnknownVariables = false;

    switch (loadEntryFile(id))
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, id);
      return null;
    }

    var oldData:MyTypeData_v0_1_x = parser.value;
    return migrateData_v0_1_x(oldData);
  }

  function migrateData_v0_1_x(input:MyTypeData_v0_1_x):MyTypeData
  {
    return {
      version: DATA_VERSION,
      id: '${input.id}',
      name: input.name,
      data: []
    };
  }

  public override function parseEntryDataWithMigration(id:String, version:thx.semver.Version):Null<MyTypeData>
  {
    if (VersionUtil.validateVersion(version, "0.1.x"))
    {
      trace('Migrating mytype data from ${version} to ${DATA_VERSION}');
      return parseEntryData_v0_1_x(id);
    }
    else
    {
      trace('Parsing mytype data with version ${version}');
      return super.parseEntryDataWithMigration(id, version);
    }
  }

  function createScriptedEntry(clsName:String):MyType
  {
    return null;
  }

  function getScriptedClassNames():Array<String>
  {
    return [];
  }
}
