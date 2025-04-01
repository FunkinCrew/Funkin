package funkin.util;

import haxe.io.Bytes;
import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.SerializerUtil;

typedef FooBar =
{
  a:Int,
  b:Int,
  c:Int
};

@:nullSafety
@:access(funkin.util.SerializerUtil)
class SerializerUtilTest extends FunkinTest
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
  public function testToJSON()
  {
    var object = {a: 1, b: 2, c: 3};
    var json = SerializerUtil.toJSON(object);
    Assert.areEqual('{' + '\n\t"a": 1,' + '\n\t"b": 2,' + '\n\t"c": 3' + '\n}', json);
  }

  @Test
  public function testFromJSON()
  {
    var json = '{' + '\n\t"a": 1,' + '\n\t"b": 2,' + '\n\t"c": 3' + '\n}';
    var object = SerializerUtil.fromJSON(json);
    Assert.areEqual(1, object.a);
    Assert.areEqual(2, object.b);
    Assert.areEqual(3, object.c);
  }

  @Test
  public function testFromJSONBytes()
  {
    var json = '{' + '\n\t"a": 1,' + '\n\t"b": 2,' + '\n\t"c": 3' + '\n}';
    var bytes = Bytes.ofString(json);

    var object = SerializerUtil.fromJSONBytes(bytes);
    Assert.areEqual(1, object.a);
    Assert.areEqual(2, object.b);
    Assert.areEqual(3, object.c);
  }

  @Test
  public function testReplacer()
  {
    var version:thx.semver.Version = '1.0.0-beta';

    Assert.areEqual(1, version.major);
    Assert.areEqual(0, version.minor);
    Assert.areEqual(0, version.patch);
    Assert.areEqual(true, version.hasPre);
    Assert.areEqual('beta', version.pre);
    // Assert.areEqual(false, version.hasBuild);
    Assert.areEqual('', version.build);

    var formatted = SerializerUtil.replacer('version', version);

    Assert.areEqual('1.0.0-beta', formatted);

    var test2 = SerializerUtil.toJSON({version: version});

    Assert.areEqual('{' + '\n\t"version": "1.0.0-beta"' + '\n}', test2);
  }
}
