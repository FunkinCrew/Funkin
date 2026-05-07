package funkin.util;

import haxe.Http;
import haxe.Json;
import funkin.Preferences;
import lime.app.Application;
import thx.semver.Version;

using StringTools;

/**
 * Checks the FunkinCrew GitHub repository for a newer release than the running version.
 * The result is cached for the lifetime of the session.
 */
class VersionCheck
{
  static final RELEASES_URL:String = "https://api.github.com/repos/FunkinCrew/Funkin/releases/latest";
  static final TAG_PREFIX:String = "v";

  static var checked:Bool = false;
  static var cachedTag:Null<String> = null;

  /**
   * Calls `onResult(tag)` if a newer release tag exists on GitHub.
   * Silent on errors, when disabled in preferences, or on non-desktop targets.
   */
  public static function check(onResult:String->Void):Void
  {
    #if !desktop
    return;
    #else
    if (!Preferences.checkForUpdates) return;

    if (checked)
    {
      if (cachedTag != null) onResult(cachedTag);
      return;
    }

    var http = new Http(RELEASES_URL);
    // GitHub's API rejects requests without a User-Agent header.
    http.setHeader('User-Agent', 'FunkinCrew-Funkin');
    http.onData = function(data:String) {
      checked = true;
      try
      {
        var json:Dynamic = Json.parse(data);
        var tag:Null<String> = json.tag_name;
        if (tag == null) return;

        var currentStr:Null<String> = Application.current.meta.get('version');
        if (currentStr == null) return;

        var latestStr:String = tag.startsWith(TAG_PREFIX) ? tag.substr(TAG_PREFIX.length) : tag;
        var latest:Version = latestStr;
        var current:Version = currentStr;

        if (latest > current)
        {
          cachedTag = tag;
          onResult(tag);
        }
      }
      catch (_:Dynamic) {}
    };
    http.onError = function(_:String) {
      checked = true;
    };
    http.request(false);
    #end
  }
}
