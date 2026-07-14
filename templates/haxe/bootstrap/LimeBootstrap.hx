package bootstrap;

import lime.app.Application;
#if (lime_cffi && !macro)
import haxe.Resource;
import lime._internal.backend.native.NativeCFFI;
#end

@:dox(hide)
@:access(lime.app.Application)
@:access(lime.system.System)
#if (lime_cffi && !macro)
@:access(lime._internal.backend.native.NativeCFFI)
#end
#if (static_link || ios)
@:cppFileCode("\nextern \"C\" int lime_register_prims ();\n::foreach ndlls::::if (registerStatics)::extern \"C\" int ::nameSafe::_register_prims ();::end::::end::")
#end
class LimeBootstrap
{
  @:noCompletion
  public static function __init__():Void
  {
    var init = lime.app.Application;
  }

  #if !macro
  public static function registerPrims():Void
  {
    #if (lime_cffi && !macro)
    NativeCFFI.lime_haxe_resource_init(Resource.listNames, Resource.getBytes);
    #end

    #if (static_link || ios)
    untyped __cpp__("lime_register_prims ()");
    ::foreach ndlls::::if (registerStatics)::untyped __cpp__("::nameSafe::_register_prims ()");::end::::end::
    #end
  }

  public static function registerEntryPoint(create:haxe.Constraints.Function):Void
  {
    ::if (WIN_ORIENTATION != "auto")::
    lime.system.System.setHint("ORIENTATIONS", ::if (WIN_ORIENTATION == "portrait")::"Portrait PortraitUpsideDown"::else::"LandscapeLeft LandscapeRight"::end::);
    ::end::

    #if mac
    lime.system.System.setHint("VIDEO_MAC_FULLSCREEN_MENU_VISIBILITY", "1");
    #end

    lime.system.System.__registerEntryPoint("::APP_FILE::", create);

    #if !html5
    create(null);
    #end
  }

  public static function exec(app:Application):Void
  {
    final result:Int = app.exec();

    #if (sys && !ios && !nodejs)
    lime.system.System.exit(result);
    #end
  }
  #end
}
