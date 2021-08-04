package modding;

import lime.utils.Assets;
import flixel.system.FlxSound;
import utilities.CoolUtil;
import polymod.Polymod;
import polymod.backends.PolymodAssets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import llua.Lua.Lua_helper;
import flixel.FlxG;
import game.Conductor;
import states.LoadingState;
import lime.app.Application;
import states.MainMenuState;
#if linc_luajit
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import flixel.FlxSprite;
import states.PlayState;

using StringTools;

class ModchartUtilities
{
    public static var lua:State = null;

    public static var lua_Sprites:Map<String, FlxSprite> = [
        'boyfriend' => PlayState.boyfriend,
        'girlfriend' => PlayState.gf,
        'dad' => PlayState.dad,
    ];

    public static var lua_Sounds:Map<String, FlxSound> = [];

	function getActorByName(id:String):Dynamic
    {
        // lua objects or what ever
        if(lua_Sprites.get(id) == null)
        {
            if(Std.parseInt(id) == null)
                return Reflect.getProperty(PlayState.instance, id);

            @:privateAccess
            return PlayState.strumLineNotes.members[Std.parseInt(id)];
        }

        return lua_Sprites.get(id);
    }

    function getPropertyByName(id:String)
    {
        return Reflect.field(PlayState.instance,id);
    }

    public function die()
    {
        Lua.close(lua);
        lua = null;
    }

    function getLuaErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);

		return v;
	}

    function callLua(func_name : String, args : Array<Dynamic>, ?type : String) : Dynamic
    {
        var result : Any = null;

        Lua.getglobal(lua, func_name);

        for( arg in args ) {
            Convert.toLua(lua, arg);
        }

        result = Lua.pcall(lua, args.length, 1, 0);

        var p = Lua.tostring(lua, result);
        var e = getLuaErrorMessage(lua);

        if (e != null)
        {
            if (p != null)
            {
                /*
                Application.current.window.alert("LUA ERROR:\n" + p + "\nhaxe things: " + e,"Leather's Funkin' Engine Modcharts");
                lua = null; 
                LoadingState.loadAndSwitchState(new MainMenuState());
                */
            }
        }

        if( result == null) {
            return null;
        } else {
            return convert(result, type);
        }
    }

    public function setVar(var_name : String, object : Dynamic){
		Lua.pushnumber(lua, object);
		Lua.setglobal(lua, var_name);
	}

    function new()
    {
        lua = LuaL.newstate();
        LuaL.openlibs(lua);

        trace("lua version: " + Lua.version());
        trace("LuaJIT version: " + Lua.versionJIT());

        Lua.init_callbacks(lua);

        var path = Paths.lua("song data/" + PlayState.SONG.song.toLowerCase() + "/modchart");

        var result = LuaL.dofile(lua, path); // execute le file

        if(result != 0)
        {
            var mods = CoolUtil.coolTextFile(Paths.txt("modList"));

            for(x in mods)
            {
                if(result != 0)
                {
                    path = "mods/" + x + "/" + "data/song data/" + PlayState.SONG.song.toLowerCase() + "/modchart.lua";
                    result = LuaL.dofile(lua, path); // execute le file
                }
            }
        }

        if (result != 0)
        {
            Application.current.window.alert("lua COMPILE ERROR:\n" + Lua.tostring(lua,result),"Leather's Funkin' Engine Modcharts");
            lua = null;
            FlxG.switchState(new MainMenuState());
        }

        // get some fukin globals up in here bois

        setVar("difficulty", PlayState.storyDifficulty);
        setVar("bpm", Conductor.bpm);
        setVar("keyCount", PlayState.SONG.keyCount);
        setVar("scrollspeed", PlayState.SONG.speed);
        setVar("fpsCap", FlxG.save.data.fpsCap);
        setVar("downscroll", FlxG.save.data.downscroll);
        setVar("flashing", FlxG.save.data.flashing);
        setVar("distractions", FlxG.save.data.distractions);

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

        //Lua_helper.add_callback(lua,"makeSprite", makeLuaSprite);

        Lua_helper.add_callback(lua, "getProperty", getPropertyByName);

        // Lua_helper.add_callback(lua,"makeAnimatedSprite", makeAnimatedLuaSprite);
        // this one is still in development

        Lua_helper.add_callback(lua, "destroySprite", function(id:String) {
            var sprite = lua_Sprites.get(id);

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

        Lua_helper.add_callback(lua,"getCenteredWindowX",function() {
            return (Application.current.window.display.currentMode.width / 2) - (Application.current.window.width / 2);
        });

        Lua_helper.add_callback(lua,"getCenteredWindowY",function() {
            return (Application.current.window.display.currentMode.height / 2) - (Application.current.window.height / 2);
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

        // sounds

        Lua_helper.add_callback(lua, "createSound", function(id:String, file_Path:String, ?looped:Bool = false) {
            if(lua_Sounds.get(id) == null)
            {
                if(Assets.exists(file_Path))
                    lua_Sounds.set(id, new FlxSound().loadEmbedded(file_Path, looped));
                else
                    lua_Sounds.set(id, new ModdingSound().loadByteArray(PolymodAssets.getBytes(file_Path), looped));

                FlxG.sound.list.add(lua_Sounds.get(id));
            }
            else
            {
                trace("Error! Sound " + id + " already exists! Try another sound name!");
            }
        });

        Lua_helper.add_callback(lua, "removeSound",function(id:String) {
            if(lua_Sounds.get(id) != null)
            {
                var sound = lua_Sounds.get(id);
                sound.stop();
                sound.kill();
                sound.destroy();

                lua_Sounds.set(id, null);
            }
        });

        Lua_helper.add_callback(lua, "playSound",function(id:String, ?forceRestart:Bool = false) {
            if(lua_Sounds.get(id) != null)
                lua_Sounds.get(id).play(forceRestart);
        });

        Lua_helper.add_callback(lua, "stopSound",function(id:String) {
            if(lua_Sounds.get(id) != null)
                lua_Sounds.get(id).stop();
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

            setVar("defaultStrum" + i + "X", Math.floor(member.x));
            setVar("defaultStrum" + i + "Y", Math.floor(member.y));
            setVar("defaultStrum" + i + "Angle", Math.floor(member.angle));

            trace("Adding strum" + i);
        }
    }

    private function convert(v : Any, type : String) : Dynamic { // I didn't write this lol
        if(Std.isOfType(v, String) && type != null ) {
            var v : String = v;

            if( type.substr(0, 4) == 'array' )
            {
                if( type.substr(4) == 'float' ) {
                    var array : Array<String> = v.split(',');
                    var array2 : Array<Float> = new Array();

                    for( vars in array ) {
                        array2.push(Std.parseFloat(vars));
                    }

                    return array2;
                    }
                    else if( type.substr(4) == 'int' ) {
                    var array : Array<String> = v.split(',');
                    var array2 : Array<Int> = new Array();

                    for( vars in array ) {
                        array2.push(Std.parseInt(vars));
                    }

                    return array2;
                    } 
                    else {
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

    public function getVar(var_name : String, type : String) : Dynamic {
		var result : Any = null;

		// trace('getting variable ' + var_name + ' with a type of ' + type);

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua,-1);
		Lua.pop(lua, 1);

		if( result == null ) {
		return null;
		} else {
		var result = convert(result, type);
		//trace(var_name + ' result: ' + result);
		return result;
		}
	}

    public function executeState(name,args:Array<Dynamic>)
    {
        return Lua.tostring(lua, callLua(name, args));
    }

    public static function createModchartUtilities():ModchartUtilities
    {
        return new ModchartUtilities();
    }
}
#end