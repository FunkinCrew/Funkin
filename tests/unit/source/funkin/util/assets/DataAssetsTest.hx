package funkin.util.assets;

import openfl.utils.Assets;
import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.assets.DataAssets;

@:nullSafety
@:access(funkin.util.assets.DataAssets)
class DataAssetsTest extends FunkinTest
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
  public function testBuildDataPath()
  {
    Assert.areEqual('assets/data/test.json', DataAssets.buildDataPath('test.json'));
  }

  @Test
  public function listDataFilesInPath()
  {
    var expected = ['blablabla', 'test1', 'test2'];

    Assert.areEqual(expected, DataAssets.listDataFilesInPath('test/'));
  }
}
