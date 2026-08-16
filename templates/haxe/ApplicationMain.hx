package;

@:dox(hide)
class ApplicationMain
{
  #if !macro

  public static function main():Void
  {
    // Registers libraries prim symbols.
    bootstrap.LimeBootstrap.registerPrims();

    #if (windows && cpp)
    // Disable the Windows "ghosting" effect that dims unresponsive windows.
    funkin.external.windows.WinAPI.disableWindowsGhosting();

    // Disable Windows error reporting (avoids sending bug reports to Microsoft).
    funkin.external.windows.WinAPI.disableErrorReporting();
    #end

    // Initialize custom logging.
    haxe.Log.trace = funkin.util.logging.AnsiTrace.trace;

    // Get OpenFL to stop complaining so much, you can remove this line if you want to read debug messages.
    lime.utils.Log.level = INFO;

    // Print color pixel art of BF in ANSI format.
    funkin.util.logging.AnsiTrace.traceBF();

    #if (sys && !mobile)
    // The shell launches us with its own working directory when a file is dropped on the exe or a
    // `funkin:` link is opened, which would put the mods folder somewhere random.
    funkin.util.CLIUtil.resetWorkingDir();
    #end

    funkin.util.logging.CrashHandler.installNativeHandler();

    #if (FEATURE_ONE_CLICK_INSTALL && sys && !macos)
    // A one-click mod link launches the game again with the URL as an argument. If a copy is
    // already running, hand the URL over and get out before a second window is ever created.
    // macOS is exempt, LaunchServices delivers the URL to the running instance itself.
    final oneClickUrl:Null<String> = funkin.util.protocol.OneClickBridge.extractUrl(Sys.args());

    if (oneClickUrl != null && funkin.util.protocol.OneClickBridge.isInstanceLive())
    {
      funkin.util.protocol.OneClickBridge.enqueue(oneClickUrl);
      Sys.exit(0);
    }
    #end

    // Registers the application entry point.
    bootstrap.LimeBootstrap.registerEntryPoint(create);
  }

  public static function create(config:Dynamic):Void
  {
    #if (linux && cpp)
    // Requests Gamemode optimization for Linux systems.
    hxgamemode.GamemodeClient.request_start();
    #end

    // Creates the primary OpenFL application instance.
    final app:openfl.display.Application = bootstrap.OpenFLBootstrap.createApplication();

    // Set the current working directory for Android and iOS devices
    #if android
    // On Android use External Files Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir()));
    #elseif ios
    // On iOS use Documents Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory));
    #end

    // Load the game's save data from disk.
    funkin.save.Save.load();

    // Creates primary OpenFL application window.
    bootstrap.OpenFLBootstrap.createWindow(app, config, funkin.Preferences.autoFullscreen);

    #if (FEATURE_ONE_CLICK_INSTALL && macos && cpp)
    // Claim the apple event that carries incoming URLs.
    funkin.external.apple.URLSchemeExtern.installHandler();
    #end

    // Initialize the crash handler.
    funkin.util.logging.CrashHandler.initialize();

    // Query the status of the crash handler.
    funkin.util.logging.CrashHandler.queryStatus();

    // Loads the application preloader.
    bootstrap.OpenFLBootstrap.loadPreloader(app, config);

    // Executes the main application loop.
    bootstrap.LimeBootstrap.exec(app);

    #if (linux && cpp)
    // Stops Gamemode optimization upon exit.
    hxgamemode.GamemodeClient.request_end();
    #end
  }
  #end
}
