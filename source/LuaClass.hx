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

class LuaNote extends LuaClass { // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
    private static var state:State;
    public var note:Note;
    public function new(connectedNote:Note, index:Int){ 
      super();
      className= "note_" + index;

      note = connectedNote;

      properties=[
        "alpha"=>{
          defaultValue: 1 ,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedNote.alpha);
            return 1;
          },
          setter: SetNumProperty
        },
        
        "angle"=>{
          defaultValue: 1 ,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedNote.angle);
            return 1;
          },
          setter: function(l:State):Int{
            // 1 = self
            // 2 = key
            // 3 = value
            // 4 = metatable
            if(Lua.type(l,3)!=Lua.LUA_TNUMBER){
              LuaL.error(l,"invalid argument #3 (number expected, got " + Lua.typename(l,Lua.type(l,3)) + ")");
              return 0;
            }
  
            var angle = Lua.tonumber(l,3);
            connectedNote.modAngle = angle;
  
            LuaClass.DefaultSetter(l);
            return 0;
          }
        },

        "strumTime"=>{
            defaultValue: 1 ,
            getter: function(l:State,data:Any):Int{
              Lua.pushnumber(l,connectedNote.strumTime);
              return 1;
            },
            setter: function(l:State):Int{
              // 1 = self
              // 2 = key
              // 3 = value
              // 4 = metatable
              // mf you can't modify this shit
              return 0;
            }
          },

        "data"=>{
            defaultValue: 1 ,
            getter: function(l:State,data:Any):Int{
              Lua.pushnumber(l,connectedNote.noteData);
              return 1;
            },
            setter: SetNumProperty
          },

        "mustPress"=>{
            defaultValue: 1 ,
            getter: function(l:State,data:Any):Int{
              Lua.pushboolean(l,connectedNote.mustPress);
              return 1;
            },
            setter: SetNumProperty
          },

        "beat"=>{
            defaultValue: 1 ,
            getter: function(l:State,data:Any):Int{
              Lua.pushnumber(l,connectedNote.beat);
              return 1;
            },
            setter: SetNumProperty
          },

        "isSustain"=>{
            defaultValue: 1 ,
            getter: function(l:State,data:Any):Int{
              Lua.pushnumber(l,connectedNote.rawNoteData);
              return 1;
            },
            setter: SetNumProperty
          },

        "x"=> {
          defaultValue: connectedNote.x,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedNote.x);
            return 1;
          },
          setter: SetNumProperty
        },

        "tweenPos"=>{
          defaultValue:0,
          getter:function(l:State,data:Any){
            Lua.pushcfunction(l,tweenPosC);
            return 1;
          },
          setter:function(l:State){
            LuaL.error(l,"tweenPos is read-only.");
            return 0;
          }
        },

        "tweenAlpha"=>{
          defaultValue:0,
          getter:function(l:State,data:Any){
            Lua.pushcfunction(l,tweenAlphaC);
            return 1;
          },
          setter:function(l:State){
            LuaL.error(l,"tweenAlpha is read-only.");
            return 0;
          }
        },

        "tweenAngle"=>{
          defaultValue:0,
          getter:function(l:State,data:Any){
            Lua.pushcfunction(l,tweenAngleC);
            return 1;
          },
          setter:function(l:State){
            LuaL.error(l,"tweenAngle is read-only.");
            return 0;
          }
        },
        
        
        "y"=> {
          defaultValue: connectedNote.y,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedNote.y);
            return 1;
          },
          setter: SetNumProperty
        }
        
      ];
    }


    private static function findNote(time:Float,data:Int)
      {
  
        for(i in PlayState.instance.notes)
        {
          if (i.strumTime == time && i.noteData == data)
          {
            return i;
          }
        }
        return null;
      }
  
      private static function tweenPos(l:StatePointer):Int{
        // 1 = self
        // 2 = x
        // 3 = y
        // 4 = time
        var xp = LuaL.checknumber(state,2);
        var yp = LuaL.checknumber(state,3);
        var time = LuaL.checknumber(state,4);
  
        Lua.getfield(state,1,"strumTime");
        var time = Lua.tonumber(state,-1);
        Lua.getfield(state,1,"data");
        var data = Lua.tonumber(state,-1);
  
        var note = findNote(time,Math.floor(data));
  
        if (note == null)
        {
          if(Lua.type(state,3)!=Lua.LUA_TNUMBER){
            LuaL.error(state,"Failure to tween (couldn't find note " + time + ")");
            return 0;
          }
        }
  
        FlxTween.tween(note,{x: xp,y:yp},time);
  
        return 0;
      }
  
      private static function tweenAngle(l:StatePointer):Int{
        // 1 = self
        // 2 = angle
        // 3 = time
        var nangle = LuaL.checknumber(state,2);
        var time = LuaL.checknumber(state,3);
  
        Lua.getfield(state,1,"strumTime");
        var time = Lua.tonumber(state,-1);
        Lua.getfield(state,1,"data");
        var data = Lua.tonumber(state,-1);
  
        var note = findNote(time,Math.floor(data));
  
        if (note == null)
        {
          if(Lua.type(state,3)!=Lua.LUA_TNUMBER){
            LuaL.error(state,"Failure to tween (couldn't find note " + time + ")");
            return 0;
          }
        }
  
        FlxTween.tween(note,{modAngle: nangle},time);
  
        return 0;
      }
  
      private static function tweenAlpha(l:StatePointer):Int{
        // 1 = self
        // 2 = alpha
        // 3 = time
        var nalpha = LuaL.checknumber(state,2);
        var time = LuaL.checknumber(state,3);
  
        Lua.getfield(state,1,"strumTime");
        var time = Lua.tonumber(state,-1);
        Lua.getfield(state,1,"data");
        var data = Lua.tonumber(state,-1);
  
        var note = findNote(time,Math.floor(data));
  
        if (note == null)
        {
          if(Lua.type(state,3)!=Lua.LUA_TNUMBER){
            LuaL.error(state,"Failure to tween (couldn't find note " + time + ")");
            return 0;
          }
        }
  
        FlxTween.tween(note,{alpha: nalpha},time);
  
        return 0;
      }
  
      private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);
      private static var tweenAngleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAngle);
      private static var tweenAlphaC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAlpha);

    private function SetNumProperty(l:State){
      // 1 = self
      // 2 = key
      // 3 = value
      // 4 = metatable
      if(Lua.type(l,3)!=Lua.LUA_TNUMBER){
        LuaL.error(l,"invalid argument #3 (number expected, got " + Lua.typename(l,Lua.type(l,3)) + ")");
        return 0;
      }
      note.modifiedByLua = true;
      Reflect.setProperty(note,Lua.tostring(l,2),Lua.tonumber(l,3));
      return 0;
    }

    override function Register(l:State){
      state=l;
      super.Register(l);
    }
  }

  class LuaReceptor extends LuaClass { // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
    private static var state:State;
    public var sprite:StaticArrow;
    public function new(connectedSprite:StaticArrow, name:String){ 
      super();
      var defaultY = connectedSprite.y;
      var defaultX = connectedSprite.x;
      var defaultAngle = connectedSprite.angle;

      sprite = connectedSprite;

      className= name;

      properties=[
        "alpha"=>{
          defaultValue: 1 ,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedSprite.alpha);
            return 1;
          },
          setter: SetNumProperty
        },
        
        "id"=>{
          defaultValue: name ,
          getter: function(l:State,data:Any):Int{
            Lua.pushstring(l,name);
            return 1;
          },
          setter: SetNumProperty
        },

        "angle"=>{
          defaultValue: 0 ,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedSprite.angle);
            return 1;
          },
          setter: function(l:State):Int{
            // 1 = self
            // 2 = key
            // 3 = value
            // 4 = metatable
            if(Lua.type(l,3)!=Lua.LUA_TNUMBER){
              LuaL.error(l,"invalid argument #3 (number expected, got " + Lua.typename(l,Lua.type(l,3)) + ")");
              return 0;
            }
  
            var angle = Lua.tonumber(l,3);
            connectedSprite.modAngle = angle;
  
            LuaClass.DefaultSetter(l);
            return 0;
          }
        },

        "x"=> {
          defaultValue: connectedSprite.x,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedSprite.x);
            return 1;
          },
          setter: SetNumProperty
        },

        
        "y"=> {
          defaultValue: connectedSprite.y,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedSprite.y);
            return 1;
          },
          setter: SetNumProperty
        },

        "defaultAngle"=>{
          defaultValue: defaultAngle ,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,defaultAngle);
            return 1;
          },
          setter: SetNumProperty
        },

        "defaultX"=> {
          defaultValue: defaultX,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,defaultX);
            return 1;
          },
          setter: SetNumProperty
        },

        

        "tweenPos"=>{
          defaultValue:0,
          getter:function(l:State,data:Any){
            Lua.pushcfunction(l,tweenPosC);
            return 1;
          },
          setter:function(l:State){
            LuaL.error(l,"tweenPos is read-only.");
            return 0;
          }
        },

        "tweenAlpha"=>{
          defaultValue:0,
          getter:function(l:State,data:Any){
            Lua.pushcfunction(l,tweenAlphaC);
            return 1;
          },
          setter:function(l:State){
            LuaL.error(l,"tweenAlpha is read-only.");
            return 0;
          }
        },

        "tweenAngle"=>{
          defaultValue:0,
          getter:function(l:State,data:Any){
            Lua.pushcfunction(l,tweenAngleC);
            return 1;
          },
          setter:function(l:State){
            LuaL.error(l,"tweenAngle is read-only.");
            return 0;
          }
        },


        "defaultY"=> {
          defaultValue: defaultY,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,defaultY);
            return 1;
          },
          setter: function(l:State):Int{
            // 1 = self
            // 2 = key
            // 3 = value
            // 4 = metatable
            return 0;
          }
        }
        
      ];
    }

    private static function findReceptor(index:Int)
    {
      for(i in 0...PlayState.strumLineNotes.length)
        {
          if (index == i)
          {
            return PlayState.strumLineNotes.members[i];
          }
        }
      return null;
    }

    private static function tweenPos(l:StatePointer):Int{
      // 1 = self
      // 2 = x
      // 3 = y
      // 4 = time
      var xp = LuaL.checknumber(state,2);
      var yp = LuaL.checknumber(state,3);
      var time = LuaL.checknumber(state,4);

      Lua.getfield(state,1,"id");
      var index = Std.parseInt(Lua.tostring(state,-1).split('_')[1]);

      var receptor = findReceptor(index);

      if (receptor == null)
      {
        if(Lua.type(state,3)!=Lua.LUA_TNUMBER){
          LuaL.error(state,"Failure to tween (couldn't find receptor " + index + ")");
          return 0;
        }
      }

      FlxTween.tween(receptor,{x: xp,y:yp},time);

      return 0;
    }

    private static function tweenAngle(l:StatePointer):Int{
      // 1 = self
      // 2 = angle
      // 3 = time
      var nangle = LuaL.checknumber(state,2);
      var time = LuaL.checknumber(state,3);

      Lua.getfield(state,1,"id");
      var index = Std.parseInt(Lua.tostring(state,-1).split('_')[1]);

      var receptor = findReceptor(index);

      if (receptor == null)
      {
        if(Lua.type(state,3)!=Lua.LUA_TNUMBER){
          LuaL.error(state,"Failure to tween (couldn't find receptor " + index + ")");
          return 0;
        }
      }

      FlxTween.tween(receptor,{modAngle: nangle},time);

      return 0;
    }

    private static function tweenAlpha(l:StatePointer):Int{
      // 1 = self
      // 2 = alpha
      // 3 = time
      var nalpha = LuaL.checknumber(state,2);
      var time = LuaL.checknumber(state,3);

      Lua.getfield(state,1,"id");
      var index = Std.parseInt(Lua.tostring(state,-1).split('_')[1]);

      var receptor = findReceptor(index);

      if (receptor == null)
      {
        if(Lua.type(state,3)!=Lua.LUA_TNUMBER){
          LuaL.error(state,"Failure to tween (couldn't find receptor " + index + ")");
          return 0;
        }
      }

      FlxTween.tween(receptor,{alpha: nalpha},time);

      return 0;
    }

    private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);
    private static var tweenAngleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAngle);
    private static var tweenAlphaC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAlpha);

    private function SetNumProperty(l:State){
      // 1 = self
      // 2 = key
      // 3 = value
      // 4 = metatable
      if(Lua.type(l,3)!=Lua.LUA_TNUMBER){
        LuaL.error(l,"invalid argument #3 (number expected, got " + Lua.typename(l,Lua.type(l,3)) + ")");
        return 0;
      }

      sprite.modifiedByLua = true;

      Reflect.setProperty(sprite,Lua.tostring(l,2),Lua.tonumber(l,3));
      return 0;
    }

    override function Register(l:State){
      state=l;
      super.Register(l);
      trace("Registered " + className);
    }
  }

  class LuaCamera extends LuaClass { // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
    private static var state:State;
    public var cam:FlxCamera;
    public function new(connectedCamera:FlxCamera, name:String){ 
      super();
      cam = connectedCamera;

      className= name;

      properties=[
        "alpha"=>{
          defaultValue: 1 ,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedCamera.alpha);
            return 1;
          },
          setter: SetNumProperty
        },
        
        "angle"=>{
          defaultValue: 0 ,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedCamera.angle);
            return 1;
          },
          setter: SetNumProperty
        },

        "x"=> {
          defaultValue: connectedCamera.x,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedCamera.x);
            return 1;
          },
          setter: SetNumProperty
        },

        
        "y"=> {
          defaultValue: connectedCamera.y,
          getter: function(l:State,data:Any):Int{
            Lua.pushnumber(l,connectedCamera.y);
            return 1;
          },
          setter: SetNumProperty
        },
      ];
    }

    private function SetNumProperty(l:State){
      // 1 = self
      // 2 = key
      // 3 = value
      // 4 = metatable
      if(Lua.type(l,3)!=Lua.LUA_TNUMBER){
        LuaL.error(l,"invalid argument #3 (number expected, got " + Lua.typename(l,Lua.type(l,3)) + ")");
        return 0;
      }
      Reflect.setProperty(cam,Lua.tostring(l,2),Lua.tonumber(l,3));
      return 0;
    }

    override function Register(l:State){
      state=l;
      super.Register(l);
      trace("Registered " + className);
    }

  }