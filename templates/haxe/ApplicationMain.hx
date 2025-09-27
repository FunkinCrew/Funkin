package;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

#if (linux && !macro)
import hxgamemode.GamemodeClient;

@:image('art/icons/iconOG.png')
class ApplicationIcon extends lime.graphics.Image {}
#end

@:access(lime.app.Application)
@:access(lime.system.System)
@:access(openfl.display.Stage)
@:access(openfl.events.UncaughtErrorEvents)
@:dox(hide)
class ApplicationMain
{
  #if !macro
  public static function main()
  {
    lime.system.System.__registerEntryPoint("::APP_FILE::", create);

    #if (js && html5)
    #if (munit || (utest && openfl_enable_utest_legacy_mode))
    lime.system.System.embed("::APP_FILE::", null, ::WIN_WIDTH::, ::WIN_HEIGHT::);
    #end
    #else
    create(null);
    #end
  }

  public static function create(config):Void
  {
    final appMeta:Map<String, String> = [];

    appMeta.set("build", "::meta.buildNumber::");
    appMeta.set("company", "::meta.company::");
    appMeta.set("file", "::APP_FILE::");
    appMeta.set("name", "::meta.title::");
    appMeta.set("packageName", "::meta.packageName::");
    appMeta.set("version", "::meta.version::");

    ::if (config.hxtelemetry != null)::#if hxtelemetry
    appMeta.set("hxtelemetry-allocations", "::config.hxtelemetry.allocations::");
    appMeta.set("hxtelemetry-host", "::config.hxtelemetry.host::");
    #end::end::

    var app = new openfl.display.Application(appMeta);

    #if linux
    app.onCreateWindow.add(function(window:lime.ui.Window):Void
    {
      window.setIcon(new ApplicationIcon());
    });
    GamemodeClient.request_start();
    #end

    #if !disable_preloader_assets
    ManifestResources.init(config);
    #end

    #if !flash
    ::foreach windows::
    var attributes:lime.ui.WindowAttributes = {
      allowHighDPI: ::allowHighDPI::,
      alwaysOnTop: ::alwaysOnTop::,
      borderless: ::borderless::,
      // display: ::display::,
      element: null,
      frameRate: ::fps::,
      #if !web fullscreen: ::fullscreen::, #end
      height: ::height::,
      hidden: #if munit true #else ::hidden:: #end,
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

      #if sys
      lime.system.System.__parseArguments(attributes);
      #end
    }

    app.createWindow(attributes);
    ::end::
    #elseif air
    app.window.title = "::meta.title::";
    #else
    app.window.context.attributes.background = ::WIN_BACKGROUND::;
    app.window.frameRate = ::WIN_FPS::;
    #end

    #if (windows && cpp)
    // Disable the Windows "ghosting" effect that dims unresponsive windows.
    funkin.external.windows.WinAPI.disableWindowsGhosting();

    // Disable Windows error reporting (avoids sending bug reports to Microsoft).
    funkin.external.windows.WinAPI.disableErrorReporting();

    // Enable dark mode if the system theme is set to dark.
    if (funkin.external.windows.WinAPI.isSystemDarkMode())
    {
      funkin.external.windows.WinAPI.setDarkMode(true);
    }
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

    #if (sys && !ios && !nodejs && !emscripten)
    lime.system.System.exit(result);
    #end

    #if linux
    GamemodeClient.request_end();
    #end
  }

  public static function start(stage:openfl.display.Stage):Void
  {
    #if flash
    ApplicationMain.getEntryPoint();
    #else
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
    #end
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

    #if neko
    // Copy from https://github.com/HaxeFoundation/haxe/blob/development/std/neko/_std/Sys.hx#L164
    // since Sys.programPath () isn't available in __init__
    var sys_program_path = {
      var m = neko.vm.Module.local().name;
      try
      {
        sys.FileSystem.fullPath(m);
      }
      catch (e:Dynamic)
      {
        // maybe the neko module name was supplied without .n extension...
        if (!StringTools.endsWith(m, ".n"))
        {
          try
          {
            sys.FileSystem.fullPath(m + ".n");
          }
          catch (e:Dynamic)
          {
            m;
          }
        }
        else
        {
          m;
        }
      }
    };

    var loader = new neko.vm.Loader(untyped $loader);
    loader.addPath(haxe.io.Path.directory(#if (haxe_ver >= 3.3) sys_program_path #else Sys.executablePath() #end));
    loader.addPath("./");
    loader.addPath("@executable_path/");
    #end
  }
  #end
}

#if !macro
@:build(DocumentClass.build())
@:keep @:dox(hide) class DocumentClass extends ::APP_MAIN:: {}
#else
class DocumentClass
{
  macro public static function build():Array<Field>
  {
    var classType = Context.getLocalClass().get();
    var searchTypes = classType;

    while (searchTypes != null)
    {
      if (searchTypes.module == "openfl.display.DisplayObject" || searchTypes.module == "flash.display.DisplayObject")
      {
        var fields = Context.getBuildFields();

        var method = macro
        {
          current.addChild(this);
          super();
          dispatchEvent(new openfl.events.Event(openfl.events.Event.ADDED_TO_STAGE, false, false));
        }

        fields.push({ name: "new", access: [ APublic ], kind: FFun({ args: [ { name: "current", opt: false, type: macro :openfl.display.DisplayObjectContainer, value: null } ], expr: method, params: [], ret: macro :Void }), pos: Context.currentPos() });

        return fields;
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

    return null;
  }
}
#end
