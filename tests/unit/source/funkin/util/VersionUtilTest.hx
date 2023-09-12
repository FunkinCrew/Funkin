package funkin.util;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.VersionUtil;

@:access(funkin.util.VersionUtil)
class VersionUtilTest extends FunkinTest
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
  public function testValidateVersionStr()
  {
    Assert.areEqual(true, VersionUtil.validateVersionStr("1.0.0", "1.0.0"));

    Assert.areEqual(false, VersionUtil.validateVersionStr("ehe", "test"));
  }

  @Test
  public function testValidateVersion()
  {
    var version:thx.semver.Version = "1.0.0"; // implicit cast
    var versionRule:thx.semver.VersionRule = "1.0.0"; // implicit cast

    Assert.areEqual(true, VersionUtil.validateVersion(version, versionRule));

    var versionRule2:thx.semver.VersionRule = ">=3.1.0"; // implicit cast

    var version1:thx.semver.Version = "3.0.0";
    var version2:thx.semver.Version = "3.1.1";
    var version3:thx.semver.Version = "4.2.0";

    Assert.areEqual(false, VersionUtil.validateVersion(version1, versionRule2));
    Assert.areEqual(true, VersionUtil.validateVersion(version2, versionRule2));
    Assert.areEqual(true, VersionUtil.validateVersion(version3, versionRule2));
  }

  @Test
  public function testGetVersionFromJSON()
  {
    var jsonStr:String = "{ \"version\": \"3.1.0\" }";

    var version:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(jsonStr);

    Assert.isNotNull(version);

    Assert.areEqual("3.1.0", version.toString());
  }

  @Test
  public function testGetVersionFromJSONBad()
  {
    var jsonStr:String = "{ \"version\": \"bleh\" }";

    Assert.throws(String, function() {
      var version:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(jsonStr);
    });

    var jsonStr2:String = "{ \"blah\": \"3.1.0\" }";

    var version2:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(jsonStr2);

    Assert.isNull(version2);
  }
}
