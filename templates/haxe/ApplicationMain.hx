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

    #if hxvlc
    // Initialize hxvlc's Handle here so the videos are loading faster.
    hxvlc.util.Handle.init();
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

    // Initialize custom logging.
    haxe.Log.trace = funkin.util.logging.AnsiTrace.trace;

    // Get OpenFL to stop complaining so much, you can remove this line if you want to read debug messages.
    lime.utils.Log.level = INFO;

    // Print color pixel art of BF in ANSI format.
    funkin.util.logging.AnsiTrace.traceBF();

    // Load the game's save data from disk.
    funkin.save.Save.load();

    // Creates primary OpenFL application window.
    bootstrap.OpenFLBootstrap.createWindow(app, config, funkin.Preferences.autoFullscreen);

    // Manually crash the game when using a software renderer in order to give a nicer error message.
    checkRenderer(app.window.context);

    // Manually crash the game when using a software renderer in order to give a nicer error message.
    checkRenderer(app.window.context);

    #if (FEATURE_ONE_CLICK_INSTALL && macos && cpp)
    // Claim the apple event that carries incoming URLs.
    funkin.external.apple.URLSchemeExtern.installHandler();
    #end

    // Set the window's vsync.
    funkin.util.WindowUtil.setVSyncMode(funkin.Preferences.vsyncMode);

    // Initialize the crash handler.
    funkin.util.logging.CrashHandler.initialize();

    // Query the status of the crash handler.
    funkin.util.logging.CrashHandler.queryStatus();

    #if FEATURE_DISCORD_RPC
    // Initialize the discord client.
    if (funkin.Preferences.enabledDiscordRPC)
    {
      funkin.api.discord.DiscordClient.instance.init();
    }

    lime.app.Application.current.onExit.add(function(exitCode)
    {
      funkin.api.discord.DiscordClient.instance.shutdown();
    });
    #end

    #if FEATURE_HAXEUI
    // Initialize HaxeUI.
    initHaxeUI();
    #end

    // Initialize the FunkinGame instance.
    funkin.FunkinGame.init();

    // Loads the application preloader.
    bootstrap.OpenFLBootstrap.loadPreloader(app, config);

    // Executes the main application loop.
    bootstrap.LimeBootstrap.exec(app);

    #if (linux && cpp)
    // Stops Gamemode optimization upon exit.
    hxgamemode.GamemodeClient.request_end();
    #end
  }

  #if FEATURE_HAXEUI
  @:noCompletion
  private static function initHaxeUI():Void
  {
    // This has to come before Toolkit.init since locales get initialized there
    haxe.ui.locale.LocaleManager.instance.autoSetLocale = false;
    // Calling this before any HaxeUI components get used is important:
    // - It initializes the theme styles.
    // - It scans the class path and registers any HaxeUI components.
    haxe.ui.Toolkit.init();
    haxe.ui.Toolkit.theme = 'funkin-dark'; // don't be cringe
    // haxe.ui.Toolkit.theme = 'light'; // embrace cringe
    haxe.ui.Toolkit.autoScale = false;
    // Don't focus on UI elements when they first appear.
    haxe.ui.focus.FocusManager.instance.autoFocus = false;
    funkin.input.Cursor.setupHaxeUICursors();
    haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
  }
  #end

  @:noCompletion
  private static function checkRenderer(context:lime.graphics.RenderContext):Void
  {
    if (context.type != WEBGL && context.type != OPENGL && context.type != OPENGLES)
    {
      var tech:String = #if web 'WebGL' #elseif desktop 'OpenGL' #else 'OpenGL ES' #end;

      var requiredVersion:String = #if web '$tech 1.0 or newer' #elseif desktop '$tech 3.0 or newer' #else '$tech 2.0 or newer' #end;

      var desc:String = 'Failed to initialize the $tech rendering context!\n\n';

      #if web
      desc += 'Make sure your graphics card supports $requiredVersion, your graphics drivers are up to date, and hardware acceleration is enabled on your browser.';
      #elseif desktop
      desc += 'Make sure your graphics card supports $requiredVersion, and your graphics drivers are up to date.';
      #else
      desc += 'Make sure your device supports $requiredVersion.';
      #end

      funkin.util.WindowUtil.showError('Failed to initialize $tech', desc);

      lime.system.System.exit(1);
    }
  }
  #end
}
