package;

import openfl.display.BitmapData;
#if linc_luajit
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

//import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxShader;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import Type.ValueType;
import Controls;
//import DialogueBoxPsych;

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end

import ui.PreferencesMenu;

#if desktop
import Discord;
#end

#if hxCodec
import hxcodec.VideoHandler;
#end

using StringTools;

class LuaHandler {
	public static var Function_Stop:Dynamic = "##NEKO2LUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##NEKO2LUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##NEKO2LUA_FUNCTIONSTOPLUA";

	#if linc_luajit
	public var lua:State = null;
	#end
	public var closed:Bool = false;
	public var scriptName:String = '';

	#if hscript
	public static var hscript:HScript = null;
	#end

	public function new(luafile:String)
	{
		var lua:State = LuaL.newstate();
        LuaL.openlibs(lua);
        //trace("Lua version: " + Lua.version());
        //trace("LuaJIT version: " + Lua.versionJIT());

        LuaL.dofile(lua, luafile);

		try{
			var result:Dynamic = LuaL.dofile(lua, luafile);
			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace('Error on lua script! ' + resultStr);
				#if windows
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				luaTrace('Error loading lua script: "$luafile"\n' + resultStr, true, false, FlxColor.RED);
				#end
				lua = null;
				return;
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}
		scriptName = luafile;
		hscript = new HScript();
		trace('lua file loaded succesfully:' + luafile);
	
		#if linc_luajit
		Lua_helper.add_callback(lua, "setLuaValue", function(variable:String, value:Dynamic) {
			PlayState.instance.variables.set(variable,value);
		});

		Lua_helper.add_callback(lua, "getLuaValue", function(variable:String) {
			return PlayState.instance.variables.get(variable);
		});

		Lua_helper.add_callback(lua, "setInstanceValue", function(variable:String, value:Dynamic) {
			Reflect.setField(PlayState.instance, variable, value);
		});

		Lua_helper.add_callback(lua, "getInstanceValue", function(variable:String) {
			return Reflect.field(PlayState.instance, variable);
		});

		Lua_helper.add_callback(lua, "runHaxeCode", function(codeToRun:String) {
			var retVal:Dynamic = null;

			#if hscript
			hscript = new HScript();
			try {
				retVal = hscript.execute(codeToRun);
			}
			catch (e:Dynamic) {
				luaTrace(scriptName + ":" + lastCalledFunction + " - " + e, false,false, FlxColor.RED);
			}
			#else
			luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			if(retVal != null && !isOfTypes(retVal, [Bool, Int, Float, String, Array])) retVal = null;
			return retVal;
		});


		Lua_helper.add_callback(lua, "debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';
			luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
		});
		
		Lua_helper.add_callback(lua, "close", function() {
			closed = true;
			return closed;
		});

		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if desktop
			DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#end
		});

		Lua_helper.add_callback(lua, "playCutscene", function (name:String, atEndOfSong:Bool = false) {
			#if hxCodec
			PlayState.instance.inCutscene = true;
			FlxG.sound.music.stop();
		
			var video:VideoHandler = new VideoHandler();
			video.finishCallback = function()
			{
				PlayState.instance.inCutscene = false;
				if (atEndOfSong)
				{
					if (PlayState.storyPlaylist.length <= 0)
					FlxG.switchState(new StoryMenuState());
					else
					{
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase());
					FlxG.switchState(new PlayState());
					}
				}
				else
					FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
					PlayState.instance.startCountdown();
					PlayState.instance.cameraMovement();
			}
			video.playVideo(Paths.video(name).replace("videos:",""));
			#else
			PlayState.instance.inCutscene = true;
			var vid:FlxVideo = new FlxVideo(name);
			vid.finishCallback = function()
			{
				FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
				PlayState.instance.startCountdown();
				PlayState.instance.cameraMovement();
				PlayState.instance.inCutscene = false;
			};
			#end
		});
		#end
	}

	var lastCalledFunction:String = '';
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		#if linc_luajit
		if(closed) return Function_Continue;

		lastCalledFunction = func;
		try {
			if(lua == null) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL)
					luaTrace("ERROR (" + func + "): attempt to call a " + typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				luaTrace("ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			return result;
		}
		catch (e:Dynamic) {
			trace(e);
		}
		#end
		return Function_Continue;
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types)
		{
			if(Std.isOfType(value, type)) return true;
		}
		return false;
	}

	function typeToString(type:Int):String {
		#if linc_luajit
		switch(type) {
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}
		if (type <= Lua.LUA_TNIL) return "nil";
		#end
		return "unknown";
	}

	function getErrorMessage(status:Int):String {
		#if linc_luajit
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			switch(status) {
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
		#end
		return null;
	}

	public function set(variable:String, data:Dynamic) {
		#if linc_luajit
		if(lua == null) {
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop() {
		#if linc_luajit
		if(lua == null) {
			return;
		}

		Lua.close(lua);
		lua = null;
		#end
	}

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		#if linc_luajit
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text, color);
			trace(text);
		}
		#end
	}

	#if linc_luajit
	public function getBool(variable:String) {
		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) {
			return false;
		}
		return (result == 'true');
	}
	#end
}

class DebugLuaText extends FlxText
{
	private var disableTime:Float = 6;
	public var parentGroup:FlxTypedGroup<DebugLuaText>;
	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>, color:FlxColor) {
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		disableTime -= elapsed;
		if(disableTime < 0) disableTime = 0;
		if(disableTime < 1) alpha = disableTime;
	}
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	//public var isInFront:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = PreferencesMenu.getPref('antialiasing');
	}
}

#if hscript
class HScript
{
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables()
	{
		return interp.variables;
	}

	public function new()
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('Preference', Preference);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		//interp.variables.set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		interp.variables.set('FlxRuntimeShader', FlxRuntimeShader);
		#end
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		HScript.parser.line = 1;
		HScript.parser.allowTypes = true;
		return interp.execute(HScript.parser.parseString(codeToRun));
	}
}
#end