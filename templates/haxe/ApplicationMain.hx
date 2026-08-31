package;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

#if (linux && !macro)
@:image('art/icons/iconOG.png')
class ApplicationIcon extends lime.graphics.Image {}
#end

@:dox(hide)
@:access(lime.app.Application)
@:access(lime.system.System)
@:access(openfl.display.Stage)
@:access(openfl.events.UncaughtErrorEvents)
#if (static_link || ios)
@:cppFileCode("\nextern \"C\" int lime_register_prims ();\n::foreach ndlls::::if (registerStatics)::extern \"C\" int ::nameSafe::_register_prims ();::end::::end::")
#end
class ApplicationMain
{
  #if !macro

  public static function main():Void
  {
    #if (static_link || ios)
    untyped __cpp__("lime_register_prims ()");
    ::foreach ndlls::::if (registerStatics)::untyped __cpp__("::nameSafe::_register_prims ()");::end::::end::
    #end

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

    lime.system.System.__registerEntryPoint("::APP_FILE::", create);

    #if !html5
    create(null);
    #end
  }

  public static function create(config):Void
  {
    #if (linux && cpp)
    hxgamemode.GamemodeClient.request_start();
    #end

    ::if (WIN_ORIENTATION != "auto")::
    lime.system.System.setHint("ORIENTATIONS", ::if (WIN_ORIENTATION == "portrait")::"Portrait PortraitUpsideDown"::else::"LandscapeLeft LandscapeRight"::end::);
    ::end::

    final appMeta:Map<String, String> = [];

    appMeta.set("build", "::meta.buildNumber::");
    appMeta.set("company", "::meta.company::");
    appMeta.set("file", "::APP_FILE::");
    appMeta.set("name", "::meta.title::");
    appMeta.set("packageName", "::meta.packageName::");
    appMeta.set("version", "::meta.version::");

    var app = new openfl.display.Application(appMeta);

    #if linux
    app.onCreateWindow.add(function(window:lime.ui.Window):Void
    {
      window.setIcon(new ApplicationIcon());
    });
    #end

    ::foreach windows::
    var attributes:lime.ui.WindowAttributes = {
      allowHighDPI: ::allowHighDPI::,
      alwaysOnTop: ::alwaysOnTop::,
      transparent: ::transparent::,
      borderless: ::borderless::,
      element: null,
      frameRate: ::fps::,
      #if !web
      fullscreen: ::fullscreen::,
      #end
      height: ::height::,
      hidden: ::hidden::,
      maximized: ::maximized::,
      minimized: ::minimized::,
      parameters: ::parameters::,
      resizable: ::resizable::,
      title: "::title::",
      width: ::width::,
      x: ::x::,
      y: ::y::,
    };

    attributes.context = {
      antialiasing: ::antialiasing::,
      background: ::background::,
      colorDepth: ::colorDepth::,
      depth: ::depthBuffer::,
      hardware: ::hardware::,
      #if (html5 && FEATURE_SCREENSHOTS)
      preserveDrawingBuffer: true,
      #end
      stencil: ::stencilBuffer::,
      type: null,
      vsync: ::vsync::
    };

    if (app.window == null)
    {
      if (config != null)
      {
        for (field in Reflect.fields(config))
        {
          if (Reflect.hasField(attributes, field))
          {
            Reflect.setField(attributes, field, Reflect.field(config, field));
          }
          else if (Reflect.hasField(attributes.context, field))
          {
            Reflect.setField(attributes.context, field, Reflect.field(config, field));
          }
        }
      }
    }

    app.createWindow(attributes);
    ::end::

    #if (FEATURE_ONE_CLICK_INSTALL && macos && cpp)
    funkin.external.apple.URLSchemeExtern.installHandler();
    #end

    // Set the current working directory for Android and iOS devices
    #if android
    // On Android use External Files Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir()));
    #elseif ios
    // On iOS use Documents Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory));
    #end

    var preloader = getPreloader();
    app.preloader.onProgress.add (function(loaded, total)
    {
      @:privateAccess preloader.update(loaded, total);
    });
    app.preloader.onComplete.add(function()
    {
      @:privateAccess preloader.start();
    });

    preloader.onComplete.add(start.bind((cast app.window:openfl.display.Window).stage));

    #if !disable_preloader_assets
    ManifestResources.init(config);

    for (library in ManifestResources.preloadLibraries)
    {
      app.preloader.addLibrary(library);
    }

    for (name in ManifestResources.preloadLibraryNames)
    {
      app.preloader.addLibraryName(name);
    }
    #end

    app.preloader.load();

    var result = app.exec();

    #if (sys && !ios && !nodejs)
    lime.system.System.exit(result);
    #end

    #if (linux && cpp)
    hxgamemode.GamemodeClient.request_end();
    #end
  }

  public static function start(stage:openfl.display.Stage):Void
  {
    if (stage.__uncaughtErrorEvents.__enabled)
    {
      try
      {
        ApplicationMain.getEntryPoint();

        stage.dispatchEvent(new openfl.events.Event(openfl.events.Event.RESIZE, false, false));

        if (stage.window.fullscreen)
        {
          stage.dispatchEvent(new openfl.events.FullScreenEvent(openfl.events.FullScreenEvent.FULL_SCREEN, false, false, true, true));
        }
      }
      catch (e:Dynamic)
      {
        #if !display
        stage.__handleError(e);
        #end
      }
    }
    else
    {
      ApplicationMain.getEntryPoint();

      stage.dispatchEvent(new openfl.events.Event(openfl.events.Event.RESIZE, false, false));

      if (stage.window.fullscreen)
      {
        stage.dispatchEvent(new openfl.events.FullScreenEvent(openfl.events.FullScreenEvent.FULL_SCREEN, false, false, true, true));
      }
    }
  }
  #end

  macro public static function getEntryPoint()
  {
    var hasMain = false;

    switch (Context.follow(Context.getType("::APP_MAIN::")))
    {
      case TInst(t, params):

        var type = t.get();
        for (method in type.statics.get())
        {
          if (method.name == "main")
          {
            hasMain = true;
            break;
          }
        }

        if (hasMain)
        {
          return Context.parse("@:privateAccess ::APP_MAIN::.main()", Context.currentPos());
        }
        else if (type.constructor != null)
        {
          return macro
          {
            var current = stage.getChildAt (0);

            if (current == null || !(current is openfl.display.DisplayObjectContainer))
            {
              current = new openfl.display.MovieClip();
              stage.addChild(current);
            }

            new DocumentClass(cast current);
          };
        }
        else
        {
          Context.fatalError("Main class \"::APP_MAIN::\" has neither a static main nor a constructor.", Context.currentPos());
        }

      default:

        Context.fatalError("Main class \"::APP_MAIN::\" isn't a class.", Context.currentPos());
    }

    return null;
  }

  macro public static function getPreloader()
  {
    ::if (PRELOADER_NAME != "")::
    var type = Context.getType("::PRELOADER_NAME::");

    switch (type)
    {
      case TInst(classType, _):

        var searchTypes = classType.get();

        while (searchTypes != null)
        {
          if (searchTypes.pack.length == 2 && searchTypes.pack[0] == "openfl" && searchTypes.pack[1] == "display" && searchTypes.name == "Preloader")
          {
            return macro
            {
              new ::PRELOADER_NAME::();
            };
          }

          if (searchTypes.superClass != null)
          {
            searchTypes = searchTypes.superClass.t.get();
          }
          else
          {
            searchTypes = null;
          }
        }

      default:
    }

    return macro
    {
      new openfl.display.Preloader(new ::PRELOADER_NAME::());
    }
    ::else::
    return macro
    {
      new openfl.display.Preloader(new openfl.display.Preloader.DefaultPreloader());
    };
    ::end::
  }

  #if !macro
  @:noCompletion @:dox(hide) public static function __init__()
  {
    var init = lime.app.Application;
  }
  #end
}
