// this file is for modchart things, this is to declutter playstate.hx

// Lua
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
#if windows
import flixel.tweens.FlxEase;
import openfl.filters.ShaderFilter;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import lime.app.Application;
import flixel.FlxSprite;
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;

class ModchartState 
{
	//public static var shaders:Array<LuaShader> = null;

	public static var lua:State = null;

	function callLua(func_name : String, args : Array<Dynamic>, ?type : String) : Dynamic
	{
		var result : Any = null;

		Lua.getglobal(lua, func_name);

		for( arg in args ) {
		Convert.toLua(lua, arg);
		}

		result = Lua.pcall(lua, args.length, 1, 0);
		var p = Lua.tostring(lua,result);
		var e = getLuaErrorMessage(lua);

		if (e != null)
		{
			if (p != null)
				{
					Application.current.window.alert("LUA ERROR:\n" + p + "\nhaxe things: " + e,"Kade Engine Modcharts");
					lua = null;
					LoadingState.loadAndSwitchState(new MainMenuState());
				}
			// trace('err: ' + e);
		}
		if( result == null) {
			return null;
		} else {
			return convert(result, type);
		}

	}

	static function toLua(l:State, val:Any):Bool {
		switch (Type.typeof(val)) {
			case Type.ValueType.TNull:
				Lua.pushnil(l);
			case Type.ValueType.TBool:
				Lua.pushboolean(l, val);
			case Type.ValueType.TInt:
				Lua.pushinteger(l, cast(val, Int));
			case Type.ValueType.TFloat:
				Lua.pushnumber(l, val);
			case Type.ValueType.TClass(String):
				Lua.pushstring(l, cast(val, String));
			case Type.ValueType.TClass(Array):
				Convert.arrayToLua(l, val);
			case Type.ValueType.TObject:
				objectToLua(l, val);
			default:
				trace("haxe value not supported - " + val + " which is a type of " + Type.typeof(val));
				return false;
		}

		return true;

	}

	static function objectToLua(l:State, res:Any) {

		var FUCK = 0;
		for(n in Reflect.fields(res))
		{
			trace(Type.typeof(n).getName());
			FUCK++;
		}

		Lua.createtable(l, FUCK, 0); // TODONE: I did it

		for (n in Reflect.fields(res)){
			if (!Reflect.isObject(n))
				continue;
			Lua.pushstring(l, n);
			toLua(l, Reflect.field(res, n));
			Lua.settable(l, -3);
		}

	}

	function getType(l, type):Any
	{
		return switch Lua.type(l,type) {
			case t if (t == Lua.LUA_TNIL): null;
			case t if (t == Lua.LUA_TNUMBER): Lua.tonumber(l, type);
			case t if (t == Lua.LUA_TSTRING): (Lua.tostring(l, type):String);
			case t if (t == Lua.LUA_TBOOLEAN): Lua.toboolean(l, type);
			case t: throw 'you don goofed up. lua type error ($t)';
		}
	}

	function getReturnValues(l) {
		var lua_v:Int;
		var v:Any = null;
		while((lua_v = Lua.gettop(l)) != 0) {
			var type:String = getType(l,lua_v);
			v = convert(lua_v, type);
			Lua.pop(l, 1);
		}
		return v;
	}


	private function convert(v : Any, type : String) : Dynamic { // I didn't write this lol
		if( Std.is(v, String) && type != null ) {
		var v : String = v;
		if( type.substr(0, 4) == 'array' ) {
			if( type.substr(4) == 'float' ) {
			var array : Array<String> = v.split(',');
			var array2 : Array<Float> = new Array();

			for( vars in array ) {
				array2.push(Std.parseFloat(vars));
			}

			return array2;
			} else if( type.substr(4) == 'int' ) {
			var array : Array<String> = v.split(',');
			var array2 : Array<Int> = new Array();

			for( vars in array ) {
				array2.push(Std.parseInt(vars));
			}

			return array2;
			} else {
			var array : Array<String> = v.split(',');
			return array;
			}
		} else if( type == 'float' ) {
			return Std.parseFloat(v);
		} else if( type == 'int' ) {
			return Std.parseInt(v);
		} else if( type == 'bool' ) {
			if( v == 'true' ) {
			return true;
			} else {
			return false;
			}
		} else {
			return v;
		}
		} else {
		return v;
		}
	}

	function getLuaErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);
		return v;
	}

	public function setVar(var_name : String, object : Dynamic){
		// trace('setting variable ' + var_name + ' to ' + object);

		Lua.pushnumber(lua,object);
		Lua.setglobal(lua, var_name);
	}

	public function getVar(var_name : String, type : String) : Dynamic {
		var result : Any = null;

		// trace('getting variable ' + var_name + ' with a type of ' + type);

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua,-1);
		Lua.pop(lua,1);

		if( result == null ) {
		return null;
		} else {
		var result = convert(result, type);
		//trace(var_name + ' result: ' + result);
		return result;
		}
	}

	function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch(id)
		{
			case 'boyfriend':
                @:privateAccess
				return PlayState.boyfriend;
			case 'girlfriend':
                @:privateAccess
				return PlayState.gf;
			case 'dad':
                @:privateAccess
				return PlayState.dad;
		}
		// lua objects or what ever
		if (luaSprites.get(id) == null)
		{
			if (Std.parseInt(id) == null)
				return Reflect.getProperty(PlayState.instance,id);
			return PlayState.PlayState.strumLineNotes.members[Std.parseInt(id)];
		}
		return luaSprites.get(id);
	}

	function getPropertyByName(id:String)
	{
		return Reflect.field(PlayState.instance,id);
	}

	public static var luaSprites:Map<String,FlxSprite> = [];

	function changeDadCharacter(id:String)
	{				var olddadx = PlayState.dad.x;
					var olddady = PlayState.dad.y;
					PlayState.instance.removeObject(PlayState.dad);
					PlayState.dad = new Character(olddadx, olddady, id);
					PlayState.instance.addObject(PlayState.dad);
					PlayState.instance.iconP2.animation.play(id);
	}

	function changeBoyfriendCharacter(id:String)
	{				var oldboyfriendx = PlayState.boyfriend.x;
					var oldboyfriendy = PlayState.boyfriend.y;
					PlayState.instance.removeObject(PlayState.boyfriend);
					PlayState.boyfriend = new Boyfriend(oldboyfriendx, oldboyfriendy, id);
					PlayState.instance.addObject(PlayState.boyfriend);
					PlayState.instance.iconP2.animation.play(id);
	}

	function makeAnimatedLuaSprite(spritePath:String,names:Array<String>,prefixes:Array<String>,startAnim:String, id:String)
	{
		#if sys
		var data:BitmapData = BitmapData.fromFile(Sys.getCwd() + "assets/data/" + PlayState.SONG.song.toLowerCase() + '/' + spritePath + ".png");

		var sprite:FlxSprite = new FlxSprite(0,0);

		sprite.frames = FlxAtlasFrames.fromSparrow(FlxGraphic.fromBitmapData(data), Sys.getCwd() + "assets/data/" + PlayState.SONG.song.toLowerCase() + "/" + spritePath + ".xml");

		trace(sprite.frames.frames.length);

		for (p in 0...names.length)
		{
			var i = names[p];
			var ii = prefixes[p];
			sprite.animation.addByPrefix(i,ii,24,false);
		}

		luaSprites.set(id,sprite);

        PlayState.instance.addObject(sprite);

		sprite.animation.play(startAnim);
		return id;
		#end
	}

	function makeLuaSprite(spritePath:String,toBeCalled:String, drawBehind:Bool)
	{
		#if sys
		var data:BitmapData = BitmapData.fromFile(Sys.getCwd() + "assets/data/" + PlayState.SONG.song.toLowerCase() + '/' + spritePath + ".png");

		var sprite:FlxSprite = new FlxSprite(0,0);
		var imgWidth:Float = FlxG.width / data.width;
		var imgHeight:Float = FlxG.height / data.height;
		var scale:Float = imgWidth <= imgHeight ? imgWidth : imgHeight;

		// Cap the scale at x1
		if (scale > 1)
			scale = 1;

		sprite.makeGraphic(Std.int(data.width * scale),Std.int(data.width * scale),FlxColor.TRANSPARENT);

		var data2:BitmapData = sprite.pixels.clone();
		var matrix:Matrix = new Matrix();
		matrix.identity();
		matrix.scale(scale, scale);
		data2.fillRect(data2.rect, FlxColor.TRANSPARENT);
		data2.draw(data, matrix, null, null, null, true);
		sprite.pixels = data2;
		
		luaSprites.set(toBeCalled,sprite);
		// and I quote:
		// shitty layering but it works!
        @:privateAccess
        {
            if (drawBehind)
            {
                PlayState.instance.removeObject(PlayState.gf);
                PlayState.instance.removeObject(PlayState.boyfriend);
                PlayState.instance.removeObject(PlayState.dad);
            }
            PlayState.instance.addObject(sprite);
            if (drawBehind)
            {
                PlayState.instance.addObject(PlayState.gf);
                PlayState.instance.addObject(PlayState.boyfriend);
                PlayState.instance.addObject(PlayState.dad);
            }
        }
		#end
		return toBeCalled;
	}

    public function die()
    {
        Lua.close(lua);
		lua = null;
    }

    // LUA SHIT

    function new()
    {
        		trace('opening a lua state (because we are cool :))');
				lua = LuaL.newstate();
				LuaL.openlibs(lua);
				trace("Lua version: " + Lua.version());
				trace("LuaJIT version: " + Lua.versionJIT());
				Lua.init_callbacks(lua);
				
				//shaders = new Array<LuaShader>();

				var result = LuaL.dofile(lua, Paths.lua(PlayState.SONG.song.toLowerCase() + "/modchart")); // execute le file
	
				if (result != 0)
				{
					Application.current.window.alert("LUA COMPILE ERROR:\n" + Lua.tostring(lua,result),"Kade Engine Modcharts");
					lua = null;
					LoadingState.loadAndSwitchState(new MainMenuState());
				}

				// get some fukin globals up in here bois
	
				setVar("difficulty", PlayState.storyDifficulty);
				setVar("bpm", Conductor.bpm);
				setVar("scrollspeed", FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
				setVar("fpsCap", FlxG.save.data.fpsCap);
				setVar("downscroll", FlxG.save.data.downscroll);
	
				setVar("curStep", 0);
				setVar("curBeat", 0);
				setVar("crochet", Conductor.stepCrochet);
				setVar("safeZoneOffset", Conductor.safeZoneOffset);
	
				setVar("hudZoom", PlayState.instance.camHUD.zoom);
				setVar("cameraZoom", FlxG.camera.zoom);
	
				setVar("cameraAngle", FlxG.camera.angle);
				setVar("camHudAngle", PlayState.instance.camHUD.angle);
	
				setVar("followXOffset",0);
				setVar("followYOffset",0);
	
				setVar("showOnlyStrums", false);
				setVar("strumLine1Visible", true);
				setVar("strumLine2Visible", true);
	
				setVar("screenWidth",FlxG.width);
				setVar("screenHeight",FlxG.height);
				setVar("windowWidth",FlxG.width);
				setVar("windowHeight",FlxG.height);
				setVar("hudWidth", PlayState.instance.camHUD.width);
				setVar("hudHeight", PlayState.instance.camHUD.height);
	
				setVar("mustHit", false);

				setVar("strumLineY", PlayState.instance.strumLine.y);
				
				// callbacks
	
				// sprites
	
				Lua_helper.add_callback(lua,"makeSprite", makeLuaSprite);
				
				Lua_helper.add_callback(lua,"changeDadCharacter", changeDadCharacter);

				Lua_helper.add_callback(lua,"changeBoyfriendCharacter", changeBoyfriendCharacter);
	
				Lua_helper.add_callback(lua,"getProperty", getPropertyByName);
				
				// Lua_helper.add_callback(lua,"makeAnimatedSprite", makeAnimatedLuaSprite);
				// this one is still in development

				Lua_helper.add_callback(lua,"destroySprite", function(id:String) {
					var sprite = luaSprites.get(id);
					if (sprite == null)
						return false;
					PlayState.instance.removeObject(sprite);
					return true;
				});

				
	
				// hud/camera
	
				Lua_helper.add_callback(lua,"setHudAngle", function (x:Float) {
					PlayState.instance.camHUD.angle = x;
				});
				
				Lua_helper.add_callback(lua,"setHealth", function (heal:Float) {
					PlayState.instance.health = heal;
				});

				Lua_helper.add_callback(lua,"setHudPosition", function (x:Int, y:Int) {
					PlayState.instance.camHUD.x = x;
					PlayState.instance.camHUD.y = y;
				});
	
				Lua_helper.add_callback(lua,"getHudX", function () {
					return PlayState.instance.camHUD.x;
				});
	
				Lua_helper.add_callback(lua,"getHudY", function () {
					return PlayState.instance.camHUD.y;
				});
				
				Lua_helper.add_callback(lua,"setCamPosition", function (x:Int, y:Int) {
					FlxG.camera.x = x;
					FlxG.camera.y = y;
				});
	
				Lua_helper.add_callback(lua,"getCameraX", function () {
					return FlxG.camera.x;
				});
	
				Lua_helper.add_callback(lua,"getCameraY", function () {
					return FlxG.camera.y;
				});
	
				Lua_helper.add_callback(lua,"setCamZoom", function(zoomAmount:Float) {
					FlxG.camera.zoom = zoomAmount;
				});
	
				Lua_helper.add_callback(lua,"setHudZoom", function(zoomAmount:Float) {
					PlayState.instance.camHUD.zoom = zoomAmount;
				});
	
				// strumline

				Lua_helper.add_callback(lua, "setStrumlineY", function(y:Float)
				{
					PlayState.instance.strumLine.y = y;
				});
	
				// actors
				
				Lua_helper.add_callback(lua,"getRenderedNotes", function() {
					return PlayState.instance.notes.length;
				});
	
				Lua_helper.add_callback(lua,"getRenderedNoteX", function(id:Int) {
					return PlayState.instance.notes.members[id].x;
				});
	
				Lua_helper.add_callback(lua,"getRenderedNoteY", function(id:Int) {
					return PlayState.instance.notes.members[id].y;
				});

				Lua_helper.add_callback(lua,"getRenderedNoteType", function(id:Int) {
					return PlayState.instance.notes.members[id].noteData;
				});

				Lua_helper.add_callback(lua,"isSustain", function(id:Int) {
					return PlayState.instance.notes.members[id].isSustainNote;
				});

				Lua_helper.add_callback(lua,"isParentSustain", function(id:Int) {
					return PlayState.instance.notes.members[id].prevNote.isSustainNote;
				});

				
				Lua_helper.add_callback(lua,"getRenderedNoteParentX", function(id:Int) {
					return PlayState.instance.notes.members[id].prevNote.x;
				});

				Lua_helper.add_callback(lua,"getRenderedNoteParentY", function(id:Int) {
					return PlayState.instance.notes.members[id].prevNote.y;
				});

				Lua_helper.add_callback(lua,"getRenderedNoteHit", function(id:Int) {
					return PlayState.instance.notes.members[id].mustPress;
				});

				Lua_helper.add_callback(lua,"getRenderedNoteCalcX", function(id:Int) {
					if (PlayState.instance.notes.members[id].mustPress)
						return PlayState.playerStrums.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
					return PlayState.strumLineNotes.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
				});

				Lua_helper.add_callback(lua,"anyNotes", function() {
					return PlayState.instance.notes.members.length != 0;
				});

				Lua_helper.add_callback(lua,"getRenderedNoteStrumtime", function(id:Int) {
					return PlayState.instance.notes.members[id].strumTime;
				});
	
				Lua_helper.add_callback(lua,"getRenderedNoteScaleX", function(id:Int) {
					return PlayState.instance.notes.members[id].scale.x;
				});
	
				Lua_helper.add_callback(lua,"setRenderedNotePos", function(x:Float,y:Float, id:Int) {
					if (PlayState.instance.notes.members[id] == null)
						throw('error! you cannot set a rendered notes position when it doesnt exist! ID: ' + id);
					else
					{
						PlayState.instance.notes.members[id].modifiedByLua = true;
						PlayState.instance.notes.members[id].x = x;
						PlayState.instance.notes.members[id].y = y;
					}
				});
	
				Lua_helper.add_callback(lua,"setRenderedNoteAlpha", function(alpha:Float, id:Int) {
					PlayState.instance.notes.members[id].modifiedByLua = true;
					PlayState.instance.notes.members[id].alpha = alpha;
				});
	
				Lua_helper.add_callback(lua,"setRenderedNoteScale", function(scale:Float, id:Int) {
					PlayState.instance.notes.members[id].modifiedByLua = true;
					PlayState.instance.notes.members[id].setGraphicSize(Std.int(PlayState.instance.notes.members[id].width * scale));
				});

				Lua_helper.add_callback(lua,"setRenderedNoteScale", function(scaleX:Int, scaleY:Int, id:Int) {
					PlayState.instance.notes.members[id].modifiedByLua = true;
					PlayState.instance.notes.members[id].setGraphicSize(scaleX,scaleY);
				});

				Lua_helper.add_callback(lua,"getRenderedNoteWidth", function(id:Int) {
					return PlayState.instance.notes.members[id].width;
				});


				Lua_helper.add_callback(lua,"setRenderedNoteAngle", function(angle:Float, id:Int) {
					PlayState.instance.notes.members[id].modifiedByLua = true;
					PlayState.instance.notes.members[id].angle = angle;
				});
	
				Lua_helper.add_callback(lua,"setActorX", function(x:Int,id:String) {
					getActorByName(id).x = x;
				});
				
				Lua_helper.add_callback(lua,"setActorAccelerationX", function(x:Int,id:String) {
					getActorByName(id).acceleration.x = x;
				});
				
				Lua_helper.add_callback(lua,"setActorDragX", function(x:Int,id:String) {
					getActorByName(id).drag.x = x;
				});
				
				Lua_helper.add_callback(lua,"setActorVelocityX", function(x:Int,id:String) {
					getActorByName(id).velocity.x = x;
				});
				
				Lua_helper.add_callback(lua,"playActorAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false) {
					getActorByName(id).playAnim(anim, force, reverse);
				});
	
				Lua_helper.add_callback(lua,"setActorAlpha", function(alpha:Float,id:String) {
					getActorByName(id).alpha = alpha;
				});
	
				Lua_helper.add_callback(lua,"setActorY", function(y:Int,id:String) {
					getActorByName(id).y = y;
				});

				Lua_helper.add_callback(lua,"setActorAccelerationY", function(y:Int,id:String) {
					getActorByName(id).acceleration.y = y;
				});
				
				Lua_helper.add_callback(lua,"setActorDragY", function(y:Int,id:String) {
					getActorByName(id).drag.y = y;
				});
				
				Lua_helper.add_callback(lua,"setActorVelocityY", function(y:Int,id:String) {
					getActorByName(id).velocity.y = y;
				});
				
				Lua_helper.add_callback(lua,"setActorAngle", function(angle:Int,id:String) {
					getActorByName(id).angle = angle;
				});
	
				Lua_helper.add_callback(lua,"setActorScale", function(scale:Float,id:String) {
					getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scale));
				});
				
				Lua_helper.add_callback(lua, "setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String)
				{
					getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scaleX), Std.int(getActorByName(id).height * scaleY));
				});
	
				Lua_helper.add_callback(lua, "setActorFlipX", function(flip:Bool, id:String)
				{
					getActorByName(id).flipX = flip;
				});

				Lua_helper.add_callback(lua, "setActorFlipY", function(flip:Bool, id:String)
				{
					getActorByName(id).flipY = flip;
				});
	
				Lua_helper.add_callback(lua,"getActorWidth", function (id:String) {
					return getActorByName(id).width;
				});
	
				Lua_helper.add_callback(lua,"getActorHeight", function (id:String) {
					return getActorByName(id).height;
				});
	
				Lua_helper.add_callback(lua,"getActorAlpha", function(id:String) {
					return getActorByName(id).alpha;
				});
	
				Lua_helper.add_callback(lua,"getActorAngle", function(id:String) {
					return getActorByName(id).angle;
				});
	
				Lua_helper.add_callback(lua,"getActorX", function (id:String) {
					return getActorByName(id).x;
				});
	
				Lua_helper.add_callback(lua,"getActorY", function (id:String) {
					return getActorByName(id).y;
				});

				Lua_helper.add_callback(lua,"setWindowPos",function(x:Int,y:Int) {
					Application.current.window.x = x;
					Application.current.window.y = y;
				});

				Lua_helper.add_callback(lua,"getWindowX",function() {
					return Application.current.window.x;
				});

				Lua_helper.add_callback(lua,"getWindowY",function() {
					return Application.current.window.y;
				});

				Lua_helper.add_callback(lua,"resizeWindow",function(Width:Int,Height:Int) {
					Application.current.window.resize(Width,Height);
				});
				
				Lua_helper.add_callback(lua,"getScreenWidth",function() {
					return Application.current.window.display.currentMode.width;
				});

				Lua_helper.add_callback(lua,"getScreenHeight",function() {
					return Application.current.window.display.currentMode.height;
				});

				Lua_helper.add_callback(lua,"getWindowWidth",function() {
					return Application.current.window.width;
				});

				Lua_helper.add_callback(lua,"getWindowHeight",function() {
					return Application.current.window.height;
				});

	
				// tweens
				
				Lua_helper.add_callback(lua,"tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});
								
				Lua_helper.add_callback(lua,"tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});
								
				Lua_helper.add_callback(lua,"tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {zoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenPos", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});

				Lua_helper.add_callback(lua,"tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});
								
				Lua_helper.add_callback(lua,"tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenCameraZoomOut", function(toZoom:Float, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});
								
				Lua_helper.add_callback(lua,"tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {zoom:toZoom}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});

				Lua_helper.add_callback(lua,"tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});
								
				Lua_helper.add_callback(lua,"tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenCameraZoomIn", function(toZoom:Float, time:Float, onComplete:String) {
					FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});
								
				Lua_helper.add_callback(lua,"tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String) {
					FlxTween.tween(PlayState.instance.camHUD, {zoom:toZoom}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
				});

				Lua_helper.add_callback(lua,"tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {ease: FlxEase.circIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});
	
				Lua_helper.add_callback(lua,"tweenFadeOut", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
					FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {ease: FlxEase.circOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
				});

				//forgot and accidentally commit to master branch
				// shader
				
				/*Lua_helper.add_callback(lua,"createShader", function(frag:String,vert:String) {
					var shader:LuaShader = new LuaShader(frag,vert);

					trace(shader.glFragmentSource);

					shaders.push(shader);
					// if theres 1 shader we want to say theres 0 since 0 index and length returns a 1 index.
					return shaders.length == 1 ? 0 : shaders.length;
				});

				
				Lua_helper.add_callback(lua,"setFilterHud", function(shaderIndex:Int) {
					PlayState.instance.camHUD.setFilters([new ShaderFilter(shaders[shaderIndex])]);
				});

				Lua_helper.add_callback(lua,"setFilterCam", function(shaderIndex:Int) {
					FlxG.camera.setFilters([new ShaderFilter(shaders[shaderIndex])]);
				});*/

				// default strums

				for (i in 0...PlayState.strumLineNotes.length) {
					var member = PlayState.strumLineNotes.members[i];
					trace(PlayState.strumLineNotes.members[i].x + " " + PlayState.strumLineNotes.members[i].y + " " + PlayState.strumLineNotes.members[i].angle + " | strum" + i);
					//setVar("strum" + i + "X", Math.floor(member.x));
					setVar("defaultStrum" + i + "X", Math.floor(member.x));
					//setVar("strum" + i + "Y", Math.floor(member.y));
					setVar("defaultStrum" + i + "Y", Math.floor(member.y));
					//setVar("strum" + i + "Angle", Math.floor(member.angle));
					setVar("defaultStrum" + i + "Angle", Math.floor(member.angle));
					trace("Adding strum" + i);
				}
    }

    public function executeState(name,args:Array<Dynamic>)
    {
        return Lua.tostring(lua,callLua(name, args));
    }

    public static function createModchartState():ModchartState
    {
        return new ModchartState();
    }
}
#end
