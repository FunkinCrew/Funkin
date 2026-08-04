package funkin.util.protocol;

import funkin.util.FileUtil.FileWriteMode;
import haxe.io.Path;

/**
 * Handles making the operating system aware that this executable owns the `funkin-mod:` URL scheme.
 */
@:nullSafety
class ProtocolRegistrar
{
  /**
   * The name the shell displays for the scheme.
   */
  static inline final SCHEME_DESCRIPTION:String = "Friday Night Funkin' Mod Install";

  /**
   * The file name of the desktop entry we write on Linux.
   */
  static inline final LINUX_DESKTOP_FILE:String = 'funkin-mod-handler.desktop';

  /**
   * Whether this platform can register a URL scheme at all.
   */
  public static function isSupported():Bool
  {
    #if (FEATURE_ONE_CLICK_INSTALL && (windows || linux || macos))
    return true;
    #else
    return false;
    #end
  }

  /**
   * Whether the scheme is currently pointed at this executable.
   */
  public static function isRegistered():Bool
  {
    if (!isSupported()) return false;

    #if FEATURE_ONE_CLICK_INSTALL
    try
    {
      #if (windows && cpp)
      return funkin.external.windows.WinAPI.isUrlProtocolRegistered(Constants.ONE_CLICK_SCHEME, getExecutablePath());
      #elseif (macos && cpp)
      return funkin.external.apple.URLSchemeExtern.isRegistered(Constants.ONE_CLICK_SCHEME);
      #elseif linux
      final path:Null<String> = getLinuxDesktopEntryPath();
      if (path == null) return false;
      if (!FileUtil.fileExists(path)) return false;
      if (FileUtil.readStringFromPath(path).indexOf(getExecutablePath()) == -1) return false;

      // The desktop entry on its own does nothing, the association is what the shell reads.
      return hasLinuxMimeAssociation();
      #end
    }
    catch (e:Dynamic)
    {
      trace('Failed to check one-click protocol registration: ${e}');
    }
    #end

    return false;
  }

  /**
   * Claims the scheme for this executable.
   *
   * @return Whether the scheme belongs to us once the call returns.
   */
  public static function register():Bool
  {
    if (!isSupported()) return false;

    #if FEATURE_ONE_CLICK_INSTALL
    try
    {
      #if (windows && cpp)
      return funkin.external.windows.WinAPI.registerUrlProtocol(Constants.ONE_CLICK_SCHEME, SCHEME_DESCRIPTION, getExecutablePath());
      #elseif (macos && cpp)
      return funkin.external.apple.URLSchemeExtern.register(Constants.ONE_CLICK_SCHEME);
      #elseif linux
      return registerLinux();
      #end
    }
    catch (e:Dynamic)
    {
      trace('Failed to register one-click protocol: ${e}');
    }
    #end

    return false;
  }

  /**
   * Releases the scheme.
   *
   * @return Whether the scheme is no longer ours once the call returns.
   */
  public static function unregister():Bool
  {
    if (!isSupported()) return false;

    #if FEATURE_ONE_CLICK_INSTALL
    try
    {
      #if (windows && cpp)
      return funkin.external.windows.WinAPI.unregisterUrlProtocol(Constants.ONE_CLICK_SCHEME);
      #elseif linux
      final path:Null<String> = getLinuxDesktopEntryPath();
      if (path == null) return false;
      if (FileUtil.fileExists(path)) FileUtil.deleteFile(path);
      updateLinuxMimeApps(true);
      refreshLinuxDesktopDatabase();
      return true;
      #elseif macos
      return false;
      #end
    }
    catch (e:Dynamic)
    {
      trace('Failed to unregister one-click protocol: ${e}');
    }
    #end

    return false;
  }

  #if sys
  /**
   * The path to the executable that should handle the scheme.
   * Windows and linux require an absolute path, while macOS uses the bundle identifier instead.
   */
  static function getExecutablePath():String
  {
    return Sys.programPath();
  }
  #else
  static function getExecutablePath():String
  {
    return '';
  }
  #end

  #if linux
  /**
   * Where the desktop entry lives, honouring XDG_DATA_HOME if the user set it.
   */
  static function getLinuxDesktopEntryPath():Null<String>
  {
    final dataHome:Null<String> = getLinuxDataHome();
    if (dataHome == null) return null;

    return Path.join([dataHome, 'applications', LINUX_DESKTOP_FILE]);
  }

  /**
   * Where the user's mime associations live, honouring XDG_CONFIG_HOME if the user set it.
   */
  static function getLinuxMimeAppsPath():Null<String>
  {
    var configHome:Null<String> = Sys.getEnv('XDG_CONFIG_HOME');

    if (configHome == null || configHome == '')
    {
      final home:Null<String> = Sys.getEnv('HOME');
      if (home == null || home == '') return null;

      configHome = Path.join([home, '.config']);
    }

    return Path.join([configHome, 'mimeapps.list']);
  }

  static function getLinuxDataHome():Null<String>
  {
    var dataHome:Null<String> = Sys.getEnv('XDG_DATA_HOME');
    if (dataHome != null && dataHome != '') return dataHome;

    final home:Null<String> = Sys.getEnv('HOME');
    if (home == null || home == '') return null;

    return Path.join([home, '.local', 'share']);
  }

  static function registerLinux():Bool
  {
    final path:Null<String> = getLinuxDesktopEntryPath();
    if (path == null)
    {
      trace('Could not resolve a data directory to write the desktop entry to.');
      return false;
    }

    // A desktop entry that only advertises the scheme handler, so it does not show up as a second
    // copy of the game in the application launcher.
    final entry:String = [
      '[Desktop Entry]',
      'Type=Application',
      'Name=${SCHEME_DESCRIPTION}',
      'Exec=${getExecutablePath()} %u',
      'Terminal=false',
      'NoDisplay=true',
      'MimeType=x-scheme-handler/${Constants.ONE_CLICK_SCHEME};',
      ''
    ].join('\n');

    FileUtil.createDirIfNotExists(Path.directory(path));
    FileUtil.writeStringToPath(path, entry, Force);

    refreshLinuxDesktopDatabase();

    // xdg-mime is part of xdg-utils, which is installed by default on most distros.
    // If it is not present, the user can still manually add it I think.
    Sys.command('xdg-mime', ['default', LINUX_DESKTOP_FILE, 'x-scheme-handler/${Constants.ONE_CLICK_SCHEME}']);

    updateLinuxMimeApps(false);

    return isRegistered();
  }

  static function refreshLinuxDesktopDatabase():Void
  {
    final dataHome:Null<String> = getLinuxDataHome();
    if (dataHome == null) return;

    // Not every distro ships desktop-file-utils, so a failure here is not fatal.
    Sys.command('update-desktop-database', [Path.join([dataHome, 'applications'])]);
  }

  /**
   * The association line the shell looks for.
   */
  static function getLinuxMimeEntry():String
  {
    return 'x-scheme-handler/${Constants.ONE_CLICK_SCHEME}=${LINUX_DESKTOP_FILE}';
  }

  static function hasLinuxMimeAssociation():Bool
  {
    final path:Null<String> = getLinuxMimeAppsPath();
    if (path == null) return false;
    if (!FileUtil.fileExists(path)) return false;

    return FileUtil.readStringFromPath(path).indexOf(getLinuxMimeEntry()) != -1;
  }

  /**
   * Adds or removes our scheme association in mimeapps.list.
   */
  static function updateLinuxMimeApps(remove:Bool):Void
  {
    final path:Null<String> = getLinuxMimeAppsPath();
    if (path == null) return;

    final key:String = 'x-scheme-handler/${Constants.ONE_CLICK_SCHEME}=';
    final lines:Array<String> = FileUtil.fileExists(path) ? FileUtil.readStringFromPath(path).split('\n') : [];

    final kept:Array<String> = [];
    for (line in lines)
    {
      if (StringTools.startsWith(StringTools.ltrim(line), key)) continue;

      kept.push(line);
    }

    if (!remove)
    {
      insertUnderSection(kept, '[Default Applications]', getLinuxMimeEntry());
      insertUnderSection(kept, '[Added Associations]', '${getLinuxMimeEntry()};');
    }

    FileUtil.createDirIfNotExists(Path.directory(path));
    FileUtil.writeStringToPath(path, kept.join('\n'), Force);
  }

  /**
   * Puts a line directly under the given section header, or creates the section if it does not exist.
   */
  static function insertUnderSection(lines:Array<String>, section:String, entry:String):Void
  {
    for (i in 0...lines.length)
    {
      if (StringTools.trim(lines[i]) != section) continue;

      lines.insert(i + 1, entry);
      return;
    }

    if (lines.length > 0 && StringTools.trim(lines[lines.length - 1]) != '') lines.push('');

    lines.push(section);
    lines.push(entry);
    lines.push('');
  }
  #end
}
