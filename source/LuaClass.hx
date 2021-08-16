import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import flixel.util.FlxAxes;
import flixel.FlxSprite;
import lime.app.Application;
import openfl.Lib;
import sys.io.File;
import flash.display.BitmapData;
import sys.FileSystem;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.DynamicAccess;

// completely yoinked from andromeda (thats what you get for stealing my callback inputs you fuckers /j)

typedef LuaProperty = {
    var defaultValue:Any;
    var getter:(State,Any)->Int;
    var setter:State->Int;
}

class LuaStorage {
  public static var objectProperties:Map<String,Map<String,LuaProperty>> = [];
  public static var objects:Map<String,LuaClass> = [];
}

class LuaClass {
  public var properties:Map<String,LuaProperty> = [];
  public var methods:Map<String,cpp.Callable<StatePointer->Int> > = [];
  public var className:String = "BaseClass";
  private static var state:State;
  public var addToGlobal:Bool=true;
  public function Register(l:State){
    Lua.newtable(l);
    state=l;
    LuaStorage.objectProperties[className]=this.properties;

    var classIdx = Lua.gettop(l);
    Lua.pushvalue(l,classIdx);
    if(addToGlobal)
      Lua.setglobal(l,className);

    for (k in methods.keys()){
      Lua.pushcfunction(l,methods[k]);
      Lua.setfield(l,classIdx,k);
    }

    LuaL.newmetatable(l,className + "Metatable");
    var mtIdx = Lua.gettop(l);
    Lua.pushstring(l, "__index");
		Lua.pushcfunction(l,cpp.Callable.fromStaticFunction(index));
		Lua.settable(l, mtIdx);

    Lua.pushstring(l, "__newindex");
		Lua.pushcfunction(l,cpp.Callable.fromStaticFunction(newindex));
		Lua.settable(l, mtIdx);

    for (k in properties.keys()){
      Lua.pushstring(l,k + "PropertyData");
      Convert.toLua(l,properties[k].defaultValue);
      Lua.settable(l,mtIdx);
    }
    Lua.pushstring(l,"_CLASSNAME");
    Lua.pushstring(l,className);
    Lua.settable(l,mtIdx);

    Lua.pushstring(l,"__metatable");
    Lua.pushstring(l,"This metatable is locked.");
    Lua.settable(l,mtIdx);

    Lua.setmetatable(l,classIdx);

  };


  private static function index(l:StatePointer):Int{
    var l = state;
    var index = Lua.tostring(l,-1);
    if(Lua.getmetatable(l,-2)!=0){
      var mtIdx = Lua.gettop(l);
      Lua.pushstring(l,index + "PropertyData");
      Lua.rawget(l,mtIdx);
      var data:Any = Convert.fromLua(l,-1);
      if(data!=null){
        Lua.pushstring(l,"_CLASSNAME");
        Lua.rawget(l,mtIdx);
        var clName = Lua.tostring(l,-1);
        if(LuaStorage.objectProperties[clName]!=null && LuaStorage.objectProperties[clName][index]!=null){
          return LuaStorage.objectProperties[clName][index].getter(l,data);
        }
      };
    }else{
      // TODO: throw an error!
    };
    return 0;
  }

  private static function newindex(l:StatePointer):Int{
    var l = state;
    var index = Lua.tostring(l,2);
    if(Lua.getmetatable(l,1)!=0){
      var mtIdx = Lua.gettop(l);
      Lua.pushstring(l,index + "PropertyData");
      Lua.rawget(l,mtIdx);
      var data:Any = Convert.fromLua(l,-1);
      if(data!=null){
        Lua.pushstring(l,"_CLASSNAME");
        Lua.rawget(l,mtIdx);
        var clName = Lua.tostring(l,-1);
        if(LuaStorage.objectProperties[clName]!=null && LuaStorage.objectProperties[clName][index]!=null){
          Lua.pop(l,2);
          return LuaStorage.objectProperties[clName][index].setter(l);
        }
      };
    }else{
      // TODO: throw an error!
    };
    return 0;
  }

  public static function SetProperty(l:State,tableIndex:Int,key:String,value:Any){
    Lua.pushstring(l,key + "PropertyData");
    Convert.toLua(l,value);
    Lua.settable(l,tableIndex  );

    Lua.pop(l,2);
  }

  public static function DefaultSetter(l:State){
    var key = Lua.tostring(l,2);

    Lua.pushstring(l,key + "PropertyData");
    Lua.pushvalue(l,3);
    Lua.settable(l,4);

    Lua.pop(l,2);
  };
  public function new(){}
}
