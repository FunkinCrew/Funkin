package funkin.util;

import thx.semver.Version;
import thx.semver.VersionRule;

/**
 * Remember, increment the patch version (1.0.x) if you make a bugfix,
 * increment the minor version (1.x.0) if you make a new feature (but previous content is still compatible),
 * and increment the major version (x.0.0) if you make a breaking change (e.g. new API or reorganized file format).
 */
class VersionUtil
{
  /**
   * Checks that a given verison number satisisfies a given version rule.
   * Version rule can be complex, e.g. "1.0.x" or ">=1.0.0,<1.1.0", or anything NPM supports.
   */
  public static function validateVersion(version:String, versionRule:String):Bool
  {
    try
    {
      var v:Version = version; // Perform a cast.
      var vr:VersionRule = versionRule; // Perform a cast.
      return v.satisfies(vr);
    }
    catch (e)
    {
      trace('[VERSIONUTIL] Invalid semantic version: ${version}');
      return false;
    }
  }
}
