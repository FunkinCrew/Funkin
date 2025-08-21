package funkin.util;

import thx.semver.Version.Identifier.StringId;

/**
 * Utility functions for operating on semantic versions.
 *
 * Remember, increment the patch version (1.0.x) if you make a bugfix,
 * increment the minor version (1.x.0) if you make a new feature (but previous content is still compatible),
 * and increment the major version (x.0.0) if you make a breaking change (e.g. new API or reorganized file format).
 */
@:nullSafety
class VersionUtil
{
  /**
   * Checks that a given verison number satisisfies a given version rule.
   * Version rule can be complex, e.g. "1.0.x" or ">=1.0.0,<1.1.0", or anything NPM supports.
   * @param version The semantic version to validate.
   * @param versionRule The version rule to validate against.
   * @return `true` if the version satisfies the rule, `false` otherwise.
   */
  public static function validateVersion(version:thx.semver.Version, versionRule:thx.semver.VersionRule):Bool
  {
    try
    {
      var versionRaw:thx.semver.Version.SemVer = version;
      return version.satisfies(versionRule);
    }
    catch (e)
    {
      trace('[VERSIONUTIL] Invalid semantic version: ${version}');
      return false;
    }
  }

  @:nullSafety(Off)
  public static function repairVersion(version:thx.semver.Version):thx.semver.Version
  {
    var versionData:thx.semver.Version.SemVer = version;

    if (thx.Types.isAnonymousObject(versionData.version))
    {
      // This is bad! versionData.version should be an array!
      trace('[SAVE] Version data repair required! (got ${versionData.version})');
      // Turn the objects back into arrays.
      // I'd use DynamicsT.values but IDK if it maintains order
      versionData.version = [versionData.version[0], versionData.version[1], versionData.version[2]];

      // This is so jank but it should work.
      var buildData:Dynamic<String> = cast versionData.build;
      var buildDataFixed:Array<thx.semver.Version.Identifier> = thx.Dynamics.DynamicsT.values(buildData)
        .map(function(d:Dynamic) return StringId(d.toString()));
      versionData.build = buildDataFixed;

      var preData:Dynamic<String> = cast versionData.pre;
      var preDataFixed:Array<thx.semver.Version.Identifier> = thx.Dynamics.DynamicsT.values(preData).map(function(d:Dynamic) return StringId(d.toString()));
      versionData.pre = preDataFixed;

      var fixedVersion:thx.semver.Version = versionData;
      trace('[SAVE] Fixed version: ${fixedVersion}');
      return fixedVersion;
    }
    else
    {
      trace('[SAVE] Version data repair not required (got ${version})');
      // No need for repair.
      return version;
    }
  }

  /**
   * Checks that a given verison number satisisfies a given version rule.
   * Version rule can be complex, e.g. "1.0.x" or ">=1.0.0,<1.1.0", or anything NPM supports.
   * @param version The semantic version to validate.
   * @param versionRule The version rule to validate against.
   * @return `true` if the version satisfies the rule, `false` otherwise.
   */
  public static function validateVersionStr(version:String, versionRule:String):Bool
  {
    try
    {
      var version:thx.semver.Version = version;
      var versionRule:thx.semver.VersionRule = versionRule;
      return version.satisfies(versionRule);
    }
    catch (e)
    {
      trace('[VERSIONUTIL] Invalid semantic version: ${version}');
      return false;
    }
  }

  /**
   * Get and parse the semantic version from a JSON string.
   * @param input The JSON string to parse.
   * @return The semantic version, or null if it could not be parsed.
   */
  public static function getVersionFromJSON(input:Null<String>):Null<thx.semver.Version>
  {
    if (input == null) return null;
    var parsed:Dynamic = SerializerUtil.fromJSON(input);
    if (parsed == null) return null;
    if (parsed.version == null) return null;
    var versionStr:String = parsed.version; // Dynamic -> String cast
    var version:thx.semver.Version = versionStr; // Implicit, not explicit, cast.
    return version;
  }

  /**
   * Get and parse the semantic version from a JSON string.
   * @param input The JSON string to parse.
   * @return The semantic version, or null if it could not be parsed.
   */
  public static function parseVersion(input:Null<Dynamic>):Null<thx.semver.Version>
  {
    if (input == null) return null;

    if (Std.isOfType(input, String))
    {
      var inputStr:String = input;
      var version:thx.semver.Version = inputStr;
      return version;
    }
    else
    {
      var semVer:thx.semver.Version.SemVer = input;
      var version:thx.semver.Version = semVer;
      return version;
    }
  }
}
