package bootstrap;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

import openfl.display.Application;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.Preloader;
import openfl.display.Stage;
import openfl.display.Window;
import openfl.events.Event;
import openfl.events.FullScreenEvent;

@:dox(hide)
@:access(openfl.display.Stage)
@:access(openfl.events.UncaughtErrorEvents)
class OpenFLBootstrap
{
  #if !macro
  public static function createApplication():Application
  {
    final appMeta:Map<String, String> = [];

    appMeta.set("build", "::meta.buildNumber::");
    appMeta.set("company", "::meta.company::");
    appMeta.set("file", "::APP_FILE::");
    appMeta.set("name", "::meta.title::");
    appMeta.set("packageName", "::meta.packageName::");
    appMeta.set("version", "::meta.version::");

    final app:Application = new Application(appMeta);

    #if linux
    app.onCreateWindow.add(function(window:lime.ui.Window):Void
    {
      window.setIcon(new ApplicationIcon());
    });
    #end

    return app;
  }

  public static function createWindow(app:Application, config:Dynamic):Void
  {
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
  }

  public static function loadPreloader(app:Application, config:Dynamic):Void
  {
    var preloader = getPreloader();

    app.preloader.onProgress.add(function(loaded, total)
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
  }
  #end

  public static function start(stage:Stage):Void
  {
    if (stage.__uncaughtErrorEvents.__enabled)
    {
      try
      {
        getEntryPoint();

        stage.dispatchEvent(new Event(Event.RESIZE, false, false));

        if (stage.window.fullscreen)
        {
          stage.dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, true, true));
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
      getEntryPoint();

      stage.dispatchEvent(new Event(Event.RESIZE, false, false));

      if (stage.window.fullscreen)
      {
        stage.dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, true, true));
      }
    }
  }

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

            if (current == null || !(current is DisplayObjectContainer))
            {
              current = new MovieClip();
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
      new Preloader(new ::PRELOADER_NAME::());
    }
    ::else::
    return macro
    {
      new Preloader(new DefaultPreloader());
    };
    ::end::
  }
}
