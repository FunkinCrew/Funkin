package funkin.modding;

import polymod.Polymod.PolymodError;

@:nullSafety
class PolymodErrorHandler
{
  #if FEATURE_MULTITHREADING
  private static var queuedErrors:Array<PolymodError> = [];

  /**
   * There's a possibility for scripted registry entries to throw errors when they're initialized.
   * If the registries are loaded asynchronously, error windows would overlay one another.
   * For this reason, the errors should get added to an array and then emptied in the main thread,
   * making the window popups appear one after another.
   */
  public static function printQueuedErrors():Void
  {
    while (queuedErrors.length > 0)
    {
      @:nullSafety(Off)
      onPolymodError(queuedErrors.shift());
    }
  }
  #end

  public static function onPolymodError(error:PolymodError):Void
  {
    funkin.util.logging.CrashHandler.setContext('${error.code}: ${error.message}');

    #if FEATURE_MULTITHREADING
    if (!funkin.util.tasks.TaskHandler.isMainThread())
    {
      PolymodErrorHandler.queuedErrors.push(error);
      return;
    }
    #end

    // Perform an action based on the error code.
    switch (error.code)
    {
      //
      // Mod Metadata Parsing Errors
      //

      case MOD_MISSING_DIRECTORY:
        // A mod directory was included in the list of mods to load, but it isn't installed.
        trace(' WARNING '.warning() + 'Tried to load a mod that was not installed: ${error.message}');
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Mod Load Error', error.message);

      case MOD_MISSING_ID:
        // A mod ID was included in the list of mods to load, but it isn't installed.
        trace(' WARNING '.warning() + ' Tried to load a mod that was not installed: ${error.message}');
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Mod Load Error', error.message);

      case MOD_MISSING_METADATA:
        // A mod ID was included in the list of mods to load, but the mod folder doesn't have metadata.
        trace(' ERROR '.error() + ' Tried to load a mod with no metadata: ${error.message}');

      case MOD_METADATA_PARSE_FAILED:
        // Polymod tries to load the mod's metadata, but it could not be parsed.
        trace(' ERROR '.error() + ' Failed to parse mod metadata: ${error.message}');
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Mod Metadata Parse Error', error.message);

      case MOD_VERSION_PARSE_FAILED:
        // Polymod tries to load the mod's version, but it could not be parsed.
        trace(' ERROR '.error() + ' Failed to parse mod version: ${error.message}');
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Mod Version Parse Error', error.message);

      case MOD_API_VERSION_PARSE_FAILED:
        // Polymod tries to load the mod's API version, but it could not be parsed.
        trace(' ERROR '.error() + ' Failed to parse mod API version: ${error.message}');
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Mod API Version Parse Error', error.message);

      case MOD_MISSING_ICON:
        // A mod is missing an icon.
        trace(' WARNING '.warning() + ' A mod is missing an icon: ${error.message}');

      case MOD_ARCHIVE_READ_FAILED:
        // Notify the user via popup.
        // funkin.util.WindowUtil.showError('Mod Archive Read Error', error.message);
        // Polymod tries to load data from a mod ZIP, but
        trace(' ERROR '.error() + ' Mod archive read failed: ${error.message}');

      //
      // Mod Loading Errors
      //

      case MOD_API_VERSION_MISMATCH:
        // Polymod tried to load a mod but failed because it has the wrong API version.
        // This is an important issue that requires user attention so it can be resolved by the mod developer.
        trace(' WARNING '.warning() + ' Failed to load mod - ${error.message}');

        if (error.severity == ERROR)
        {
          // ERROR occurs when trying to load a mod that is incompatible with the game version.

          var regex:EReg = ~/Mod "([-_a-zA-Z0-9]+)" is not compatible with API version "(.*?)", got "(.*?)"/;
          if (regex.match(error.message))
          {
            // Notify the user via formatted popup if we can extract the mod ID and version.
            var modId:String = regex.matched(1);
            // var apiVersion:String = regex.matched(2);
            var modVersion:String = regex.matched(3);

            var message:String =
              'Installed mod "$modId" was built for modding version "v$modVersion". It is not compatible with game version ${Constants.GENERATED_BY}, and must be skipped.'
              + '\n\nPlease inform the mod developer that "$modId" must be updated for compatibility.';

            funkin.util.WindowUtil.showError('Mod Outdated', message);
          }
          else
          {
            // Notify the user via standard popup.
            funkin.util.WindowUtil.showError('Mod Outdated', error.message);
          }
        }
        else
        {
          // WARNING occurs when scanning for mods, and finding a mod incompatible with the game version.
        }

      case MOD_LOAD_FAILED:
        // Polymod failed to load a mod. A different error would have already been logged.
        trace(' WARNING '.warning() + ' Failed to load mod - ${error.message}');

      case MOD_LOAD_DONE:
        trace(' INFO '.info() + ' Loaded mod - ${error.message}');

      //
      // Mod Dependency Errors
      //

      case MOD_OPTIONAL_DEPENDENCY_UNMET:
        // Polymod looked at the list of available mods, and one of them was missing an optional dependency.
        trace(' INFO '.info() + ' Installed mod is missing an optional dependency: ${error.message}');

      case MOD_DEPENDENCY_UNMET:
        switch (error.origin)
        {
          case SCAN:
            // Polymod looked at the list of available mods, and one of them was missing a dependency.
            // This is an important warning that should be shown to the user.
            trace(' WARNING '.warning() + ' Installed mod is missing a dependency: ${error.message}');
            // Notify the user via popup.
            funkin.util.WindowUtil.showError('Mod Dependency Error', error.message);
          default:
            // Polymod tried to load a mod, but failed because it has a dependency that wasn't met.
            // This is a major error that should be shown to the user.
            trace(' ERROR '.error() + ' Failed to load mod due to missing dependency: ${error.message}');
            // Notify the user via popup.
            funkin.util.WindowUtil.showError('Mod Dependency Error', error.message);
        }

      case MOD_DEPENDENCY_VERSION_MISMATCH:
        switch (error.origin)
        {
          case SCAN:
            // Polymod looked at the list of available mods, and one of them has a dependency on a different mod,
            // but the mod has the wrong version.
            // This is an important warning that should be shown to the user.
            trace(' WARNING '.warning() + ' Installed mod has a mismatched dependency: ${error.message}');
            // Notify the user via popup.
            funkin.util.WindowUtil.showError('Mod Dependency Error', error.message);
          default:
            // Polymod tried to load a mod, but failed because one of its dependencies was the wrong version.
            // This is a major error that should be shown to the user.
            trace(' ERROR '.error() + ' Failed to load mod due to mismatched dependency: ${error.message}');
            // Notify the user via popup.
            funkin.util.WindowUtil.showError('Mod Dependency Error', error.message);
        }

      case MOD_DEPENDENCY_CYCLICAL:
        // Polymod tried to load a mod, but failed because one of its dependencies depends on that mod.
        // This is a major error that should be shown to the user.
        trace(' ERROR '.error() + ' Failed to load mod due to cyclical dependency: ${error.message}');
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Mod Dependency Error', error.message);

      //
      // Script Parsing Errors
      //

      case SCRIPT_PARSE_FAILED:
        // A syntax error when parsing a script.
        trace(' ERROR '.error() + ' ' + error.message);
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Script Parsing Error', error.message);

      case SCRIPT_RUNTIME_EXCEPTION:
        // A runtime error when running a script.
        trace(' ERROR '.error() + ' ' + error.message);
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Script Exception', error.message);

      case SCRIPTED_CLASS_NOT_REGISTERED:
        // Polymod attempted to initialize a scripted class, but it wasn't registered.
        trace(' ERROR '.error() + ' ' + error.message);
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Script Parsing Error', error.message);

      case SCRIPTED_CLASS_ALREADY_REGISTERED:
        // Polymod attempted to register a scripted class, but one with the same name and package already exists.
        trace(' ERROR '.error() + ' ' + error.message);
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Script Parsing Error', error.message);

      case SCRIPTED_CLASS_REDUNDANT_IMPORT:
        // A scripted class imported a module that's already imported.
        trace(' WARNING '.warning() + ' ' + error.message);

      case SCRIPTED_CLASS_UNRESOLVED_IMPORT:
        // A scripted class tried to import a module that doesn't exist.
        trace(' ERROR '.error() + ' ' + error.message);
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Script Import Error', error.message);

      case SCRIPTED_CLASS_BLACKLISTED_MODULE:
        // A scripted class tried to import a module that's blacklisted.
        trace(' ERROR '.error() + ' ' + error.message);
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Script Blacklist Violation', error.message);

      case SCRIPTED_CLASS_BLACKLISTED_FIELD:
        // A scripted class tried to access a field that's blacklisted.
        trace(' ERROR '.error() + ' ' + error.message);
        // Notify the user via popup.
        funkin.util.WindowUtil.showError('Script Blacklist Violation', error.message);

      //
      // Other Errors
      //

      case FRAMEWORK_INIT, MOD_DEPENDENCY_CHECK_SKIPPED, SCRIPT_PARSE_START, SCRIPT_PARSE_DONE:
        // Unimportant messages that we don't need to log.
        return;

      default:
        // Log the message based on its severity.
        switch (error.severity)
        {
          case ERROR:
            trace(' ERROR '.error() + ' ' + error.message);
          case WARNING:
            trace(' WARNING '.warning() + ' ' + error.message);
          case INFO:
            trace(' INFO '.info() + ' ' + error.message);
          case DEBUG:
            // trace(' DEBUG '.bg_white() + error.message);
        }
    }
  }
}
