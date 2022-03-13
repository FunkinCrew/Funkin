package modding;

import flixel.text.FlxText;
import utilities.Options;
import openfl.display.BlendMode;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import utilities.Controls;
import backgrounds.DancingSprite;
import game.Note;
import game.Boyfriend;
import flixel.util.FlxTimer;
import ui.HealthIcon;
import game.Character;
import flixel.util.FlxColor;
#if linc_luajit
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import flixel.FlxSprite;
import states.PlayState;
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

using StringTools;

class ModchartUtilities
{
    public var lua:State = null;

    public static var lua_Sprites:Map<String, FlxSprite> = [
        'boyfriend' => PlayState.boyfriend,
        'girlfriend' => PlayState.gf,
        'dad' => PlayState.dad,
    ];

    public static var lua_Characters:Map<String, Character> = [
        'boyfriend' => PlayState.boyfriend,
        'girlfriend' => PlayState.gf,
        'dad' => PlayState.dad,
    ];

    public static var lua_Sounds:Map<String, FlxSound> = [];

    public static var lua_Shaders:Map<String, shaders.Shaders.ShaderEffect> = [];

	function getActorByName(id:String):Dynamic
    {
        // lua objects or what ever
        if(!lua_Sprites.exists(id))
        {
            if(Std.parseInt(id) == null)
                return Reflect.getProperty(PlayState.instance, id);

            @:privateAccess
            return PlayState.strumLineNotes.members[Std.parseInt(id)];
        }

        return lua_Sprites.get(id);
    }

    function getCharacterByName(id:String):Dynamic
    {
        // lua objects or what ever
        if(lua_Characters.exists(id))
            return lua_Characters.get(id);
        else
            return null;
    }

    public function die()
    {
        PlayState.songMultiplier = oldMultiplier;

        lua_Sprites.clear();
        lua_Characters.clear();
        lua_Shaders.clear();
        lua_Sounds.clear();

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

    public function setVar(var_name : String, object : Dynamic)
    {
        if(Std.isOfType(object, Bool))
            Lua.pushboolean(lua, object);
        else if(Std.isOfType(object, String))
            Lua.pushstring(lua, object);
        else
            Lua.pushnumber(lua, object);

		Lua.setglobal(lua, var_name);
	}

    var oldMultiplier:Float = PlayState.songMultiplier;

    function new(?path:Null<String>)
    {
        oldMultiplier = PlayState.songMultiplier;

        lua_Sprites.set("boyfriend", PlayState.boyfriend);
        lua_Sprites.set("girlfriend", PlayState.gf);
        lua_Sprites.set("dad", PlayState.dad);

        lua_Characters.set("boyfriend", PlayState.boyfriend);
        lua_Characters.set("girlfriend", PlayState.gf);
        lua_Characters.set("dad", PlayState.dad);

        lua_Sounds.set("Inst", FlxG.sound.music);
        @:privateAccess
        lua_Sounds.set("Voices", PlayState.instance.vocals);

        lua = LuaL.newstate();
        LuaL.openlibs(lua);

        trace("lua version: " + Lua.version());
        trace("LuaJIT version: " + Lua.versionJIT());

        Lua.init_callbacks(lua);

        if(path == null)
            path = PolymodAssets.getPath(Paths.lua("modcharts/" + PlayState.SONG.modchartPath));

        var result = LuaL.dofile(lua, path); // execute le file

        if (result != 0)
        {
            Application.current.window.alert("lua COMPILE ERROR:\n" + Lua.tostring(lua,result),"Leather Engine Modcharts");
            //FlxG.switchState(new MainMenuState());
        }

        // this might become a problem if i don't do this
        setVar("require", false);
        setVar("os", false);

        // get some fukin globals up in here bois

        setVar("difficulty", PlayState.storyDifficultyStr);
        setVar("bpm", Conductor.bpm);
        setVar("songBpm", PlayState.SONG.bpm);
        setVar("keyCount", PlayState.SONG.keyCount);
        setVar("playerKeyCount", PlayState.SONG.playerKeyCount);
        setVar("scrollspeed", PlayState.SONG.speed);
        setVar("fpsCap", utilities.Options.getData("maxFPS"));
        setVar("bot", utilities.Options.getData("botplay"));
        setVar("noDeath", utilities.Options.getData("noDeath"));
        setVar("downscroll", utilities.Options.getData("downscroll") == true ? 1 : 0); // fuck you compatibility
        setVar("downscrollBool", utilities.Options.getData("downscroll"));
	setVar("middlescroll", utilities.Options.getData("middlescroll"));
        setVar("flashingLights", utilities.Options.getData("flashingLights"));
        setVar("flashing", utilities.Options.getData("flashingLights"));
        //setVar("distractions", .distractions);
        setVar("cameraZooms", utilities.Options.getData("cameraZooms"));

        setVar("animatedBackgrounds", utilities.Options.getData("animatedBGs"));

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

        setVar("screenWidth", lime.app.Application.current.window.display.currentMode.width);
        setVar("screenHeight", lime.app.Application.current.window.display.currentMode.height);
        setVar("windowWidth", FlxG.width);
        setVar("windowHeight", FlxG.height);

        setVar("hudWidth", PlayState.instance.camHUD.width);
        setVar("hudHeight", PlayState.instance.camHUD.height);

        setVar("mustHit", false);
        setVar("strumLineY", PlayState.instance.strumLine.y);

        setVar("characterPlayingAs", PlayState.characterPlayingAs);
        setVar("inReplay", PlayState.playingReplay);
        
        // callbacks

        Lua_helper.add_callback(lua,"flashCamera", function(camera:String = "", color:String = "#FFFFFF", time:Float = 1, force:Bool = false) {
            if(utilities.Options.getData("flashingLights"))
                cameraFromString(camera).flash(FlxColor.fromString(color), time, null, force);
        });

        Lua_helper.add_callback(lua,"triggerEvent", function(event_name:String, argument_1:Dynamic, argument_2:Dynamic) {
			var string_arg_1:String = Std.string(argument_1);
			var string_arg_2:String = Std.string(argument_2);

            if(!PlayState.instance.event_luas.exists(event_name.toLowerCase()) && Assets.exists(Paths.lua("event data/" + event_name.toLowerCase())))
            {
                PlayState.instance.event_luas.set(event_name.toLowerCase(), ModchartUtilities.createModchartUtilities(PolymodAssets.getPath(Paths.lua("event data/" + event_name.toLowerCase()))));
                PlayState.instance.generatedSomeDumbEventLuas = true;
            }

            PlayState.instance.processEvent([event_name, Conductor.songPosition, string_arg_1, string_arg_2]);
        });

        Lua_helper.add_callback(lua,"setObjectCamera", function(id:String, camera:String = "") {
            var actor:FlxSprite = getActorByName(id);

            if(actor != null)
                Reflect.setProperty(actor, "cameras", [cameraFromString(camera)]);
        });

        Lua_helper.add_callback(lua,"setGraphicSize", function(id:String, width:Int = 0, height:Int = 0) {
            var actor:FlxSprite = getActorByName(id);

            if(actor != null)
                actor.setGraphicSize(width, height);
        });

        Lua_helper.add_callback(lua,"updateHitbox", function(id:String) {
            var actor:FlxSprite = getActorByName(id);

            if(actor != null)
                actor.updateHitbox();
        });

        Lua_helper.add_callback(lua, "setBlendMode", function(id:String, blend:String = '') {
            var actor:FlxSprite = getActorByName(id);

            if(actor != null)
                actor.blend = blendModeFromString(blend);
		});

        // sprites

        // stage

        Lua_helper.add_callback(lua, "makeGraphic", function(id:String, width:Int, height:Int, color:String) {
            if(getActorByName(id) != null)
                getActorByName(id).makeGraphic(width, height, FlxColor.fromString(color));
		});

        Lua_helper.add_callback(lua,"makeStageSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:FlxSprite = new FlxSprite(x, y);

                @:privateAccess
                if(filename != null && filename.length > 0)
                    Sprite.loadGraphic(Paths.image(PlayState.instance.stage.stage + "/" + filename, "stages"));

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
                Sprite.updateHitbox();
    
                lua_Sprites.set(id, Sprite);
    
                @:privateAccess
                PlayState.instance.stage.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        Lua_helper.add_callback(lua,"makeStageAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:FlxSprite = new FlxSprite(x, y);

                @:privateAccess
                if(filename != null && filename.length > 0)
                    Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
                Sprite.updateHitbox();
    
                lua_Sprites.set(id, Sprite);
    
                @:privateAccess
                PlayState.instance.stage.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        Lua_helper.add_callback(lua,"makeStageDancingSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

                @:privateAccess
                if(filename != null && filename.length > 0)
                    Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
                Sprite.updateHitbox();
    
                lua_Sprites.set(id, Sprite);
    
                @:privateAccess
                PlayState.instance.stage.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        // regular

        Lua_helper.add_callback(lua,"setActorTextColor", function(id:String, color:String) {
            if(getActorByName(id) != null)
                Reflect.setProperty(getActorByName(id), "color", FlxColor.fromString(color));
        });

        Lua_helper.add_callback(lua,"setActorText", function(id:String, text:String) {
            if(getActorByName(id) != null)
                Reflect.setProperty(getActorByName(id), "text", text);
        });

        Lua_helper.add_callback(lua,"setActorAlignment", function(id:String, align:String) {
            if(getActorByName(id) != null)
                Reflect.setProperty(getActorByName(id), "alignment", align);
        });

        Lua_helper.add_callback(lua,"makeText", function(id:String, text:String, x:Float, y:Float, size:Int = 32, font:String = "vcr.ttf", fieldWidth:Float = 0) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:FlxText = new FlxText(x, y, fieldWidth, text, size);
                Sprite.font = Paths.font(font);

    
                lua_Sprites.set(id, Sprite);
    
                PlayState.instance.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        Lua_helper.add_callback(lua,"makeSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:FlxSprite = new FlxSprite(x, y);

                if(filename != null && filename.length > 0)
                    Sprite.loadGraphic(Paths.image(filename));

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
                Sprite.updateHitbox();
    
                lua_Sprites.set(id, Sprite);
    
                PlayState.instance.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        Lua_helper.add_callback(lua,"makeAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:FlxSprite = new FlxSprite(x, y);

                if(filename != null && filename.length > 0)
                    Sprite.frames = Paths.getSparrowAtlas(filename);

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
                Sprite.updateHitbox();
    
                lua_Sprites.set(id, Sprite);
    
                PlayState.instance.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        Lua_helper.add_callback(lua,"makeDancingSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

                if(filename != null && filename.length > 0)
                    Sprite.frames = Paths.getSparrowAtlas(filename);

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
                Sprite.updateHitbox();
    
                lua_Sprites.set(id, Sprite);
    
                PlayState.instance.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        Lua_helper.add_callback(lua, "destroySprite", function(id:String) {
            var sprite = lua_Sprites.get(id);

            if (sprite == null)
                return false;

            lua_Sprites.remove(id);

            PlayState.instance.removeObject(sprite);
            sprite.kill();
            sprite.destroy();

            return true;
        });

        Lua_helper.add_callback(lua,"getIsColliding", function(sprite1Name:String, sprite2Name:String) {
            var sprite1 = getActorByName(sprite1Name);

            if(sprite1 != null)
            {
                var sprite2 = getActorByName(sprite2Name);

                if(sprite2 != null)
                    return sprite1.overlaps(sprite2);
            }

            return false;
        });

        // health
        
        Lua_helper.add_callback(lua,"getHealth",function() {
            return PlayState.instance.health;
        });

        Lua_helper.add_callback(lua,"setHealth", function (heal:Float) {
            PlayState.instance.health = heal;
        });

        Lua_helper.add_callback(lua,"getMinHealth",function() {
            return PlayState.instance.minHealth;
        });

        Lua_helper.add_callback(lua,"getMaxHealth",function() {
            return PlayState.instance.maxHealth;
        });

        Lua_helper.add_callback(lua,'changeHealthRange', function (minHealth:Float, maxHealth:Float) {
            @:privateAccess
            {
                var bar = PlayState.instance.healthBar;
                PlayState.instance.minHealth = minHealth;
                PlayState.instance.maxHealth = maxHealth;
                bar.setRange(minHealth, maxHealth);
            }
        });

        // hud/camera

        Lua_helper.add_callback(lua,"setHudAngle", function (x:Float) {
            PlayState.instance.camHUD.angle = x;
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
            @:privateAccess
            {
                PlayState.instance.camFollow.x = x;
                PlayState.instance.camFollow.y = y;
            }
        });

        Lua_helper.add_callback(lua,"getCameraX", function () {
            @:privateAccess
            return PlayState.instance.camFollow.x;
        });

        Lua_helper.add_callback(lua,"getCameraY", function () {
            @:privateAccess
            return PlayState.instance.camFollow.y;
        });

        Lua_helper.add_callback(lua,"getCamZoom", function() {
            return FlxG.camera.zoom;
        });

        Lua_helper.add_callback(lua,"getHudZoom", function() {
            return PlayState.instance.camHUD.zoom;
        });

        Lua_helper.add_callback(lua,"setCamZoom", function(zoomAmount:Float) {
            FlxG.camera.zoom = zoomAmount;
        });

        Lua_helper.add_callback(lua,"setHudZoom", function(zoomAmount:Float) {
            PlayState.instance.camHUD.zoom = zoomAmount;
        });

        // strumline

        Lua_helper.add_callback(lua, "setStrumlineY", function(y:Float, ?dontMove:Bool = false)
        {
            PlayState.instance.strumLine.y = y;

            if(!dontMove)
            {
                for(note in PlayState.strumLineNotes)
                {
                    note.y = y;
                }
            }
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

        Lua_helper.add_callback(lua,"getRenderedNoteHeight", function(id:Int) {
            return PlayState.instance.notes.members[id].height;
        });

        Lua_helper.add_callback(lua,"setRenderedNoteAngle", function(angle:Float, id:Int) {
            PlayState.instance.notes.members[id].modifiedByLua = true;
            PlayState.instance.notes.members[id].angle = angle;
        });

        Lua_helper.add_callback(lua,"setActorX", function(x:Float,id:String) {
            if(getActorByName(id) != null)
                getActorByName(id).x = x;
        });

        Lua_helper.add_callback(lua,"setActorPos", function(x:Float,y:Float,id:String) {
            var actor = getActorByName(id);

            if(actor != null)
            {
                actor.x = x;
                actor.y = y;
            }
        });

        Lua_helper.add_callback(lua,"setActorScroll", function(x:Float,y:Float,id:String) {
            var actor = getActorByName(id);

            if(getActorByName(id) != null)
            {
                actor.scrollFactor.set(x,y);
            }
        });
        
        Lua_helper.add_callback(lua,"getOriginalCharX", function(character:Int) {
            @:privateAccess
            return PlayState.instance.stage.getCharacterPos(character)[0];
        });

        Lua_helper.add_callback(lua,"getOriginalCharY", function(character:Int) {
            @:privateAccess
            return PlayState.instance.stage.getCharacterPos(character)[1];
        });
        
        Lua_helper.add_callback(lua,"setActorAccelerationX", function(x:Float,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).acceleration.x = x;
            }
        });
        
        Lua_helper.add_callback(lua,"setActorDragX", function(x:Float,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).drag.x = x;
            }
        });
        
        Lua_helper.add_callback(lua,"setActorVelocityX", function(x:Float,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).velocity.x = x;
            }
        });

        Lua_helper.add_callback(lua,"setActorAntialiasing", function(antialiasing:Bool,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).antialiasing = antialiasing;
            }
        });

        Lua_helper.add_callback(lua,"addActorAnimation", function(id:String,prefix:String,anim:String,fps:Int = 30, looped:Bool = true) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).animation.addByPrefix(prefix, anim, fps, looped);
            }
        });

        Lua_helper.add_callback(lua,"addActorAnimationIndices", function(id:String,prefix:String,indiceString:String,anim:String,fps:Int = 30, looped:Bool = true) {
            if(getActorByName(id) != null)
            {
                var indices:Array<Dynamic> = indiceString.split(",");

                for(indiceIndex in 0...indices.length)
                {
                    indices[indiceIndex] = Std.parseInt(indices[indiceIndex]);
                }

                getActorByName(id).animation.addByIndices(anim, prefix, indices, "", fps, looped);
            }
        });
        
        Lua_helper.add_callback(lua,"playActorAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false,frame:Int = 0) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).animation.play(anim, force, reverse, frame);
            }
        });
        
        Lua_helper.add_callback(lua,"playActorDance", function(id:String, ?altAnim:String = '') {
            if(getActorByName(id) != null)
            {
                getActorByName(id).dance(altAnim);
            }
        });

        Lua_helper.add_callback(lua,"playCharacterAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false,frame:Int = 0) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).playAnim(anim, force, reverse, frame);
            }
        });

        Lua_helper.add_callback(lua,"setCharacterShouldDance", function(id:String, shouldDance:Bool = true) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).shouldDance = shouldDance;
            }
        });

        Lua_helper.add_callback(lua,"playCharacterDance", function(id:String,?altAnim:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).dance(altAnim);
            }
        });

        Lua_helper.add_callback(lua,"getPlayingActorAnimation", function(id:String) {
            if(getActorByName(id) != null)
            {
                if(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim") != null)
                    return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim"), "name");
            }

            return "unknown";
        });

        Lua_helper.add_callback(lua,"getPlayingActorAnimationFrame", function(id:String) {
            if(getActorByName(id) != null)
            {
                if(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim") != null)
                    return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim"), "curFrame");
            }

            return 0;
        });

        Lua_helper.add_callback(lua,"setActorAlpha", function(alpha:Float,id:String) {
            if(getActorByName(id) != null)
                Reflect.setProperty(getActorByName(id), "alpha", alpha);
        });

        Lua_helper.add_callback(lua,"setActorVisible", function(visible:Bool,id:String) {
            if(getActorByName(id) != null)
                getActorByName(id).visible = visible;
        });

        Lua_helper.add_callback(lua,"setActorColor", function(id:String,r:Int,g:Int,b:Int,alpha:Int = 255) {
            if(getActorByName(id) != null)
            {
                Reflect.setProperty(getActorByName(id), "color", FlxColor.fromRGB(r, g, b, alpha));
            }
        });

        Lua_helper.add_callback(lua,"setActorY", function(y:Float,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).y = y;
            }
        });

        Lua_helper.add_callback(lua,"setActorAccelerationY", function(y:Float,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).acceleration.y = y;
            }
        });
        
        Lua_helper.add_callback(lua,"setActorDragY", function(y:Float,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).drag.y = y;
            }
        });
        
        Lua_helper.add_callback(lua,"setActorVelocityY", function(y:Float,id:String) {
            if(getActorByName(id) != null)
            {
                getActorByName(id).velocity.y = y;
            }
        });
        
        Lua_helper.add_callback(lua,"setActorAngle", function(angle:Float,id:String) {
            if(getActorByName(id) != null)
                Reflect.setProperty(getActorByName(id), "angle", angle);
        });

        Lua_helper.add_callback(lua,"setActorModAngle", function(angle:Float,id:String) {
            if(getActorByName(id) != null)
                getActorByName(id).modAngle = angle;
        });

        Lua_helper.add_callback(lua,"setActorScale", function(scale:Float,id:String) {
            if(getActorByName(id) != null)
                getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scale));
        });
        
        Lua_helper.add_callback(lua, "setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String)
        {
            if(getActorByName(id) != null)
                getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scaleX), Std.int(getActorByName(id).height * scaleY));
        });

        Lua_helper.add_callback(lua, "setActorFlipX", function(flip:Bool, id:String)
        {
            if(getActorByName(id) != null)
                getActorByName(id).flipX = flip;
        });

        Lua_helper.add_callback(lua, "setActorFlipY", function(flip:Bool, id:String)
        {
            if(getActorByName(id) != null)
                getActorByName(id).flipY = flip;
        });

        Lua_helper.add_callback(lua,"setActorTrailVisible", function(id:String,visibleVal:Bool) {
            var char = getCharacterByName(id);

            if(char != null)
            {
                if(char.coolTrail != null)
                {
                    char.coolTrail.visible = visibleVal;
                    return true;
                }
                else
                    return false;
            }
            else
                return false;
        });

        Lua_helper.add_callback(lua,"getActorTrailVisible", function(id:String) {
            var char = getCharacterByName(id);

            if(char != null)
            {
                if(char.coolTrail != null)
                    return char.coolTrail.visible;
                else
                    return false;
            }
            else
                return false;
        });

        Lua_helper.add_callback(lua,"getActorWidth", function (id:String) {
            if(getActorByName(id) != null)
                return getActorByName(id).width;
            else 
                return 0;
        });

        Lua_helper.add_callback(lua,"getActorHeight", function (id:String) {
            if(getActorByName(id) != null)
                return getActorByName(id).height;
            else
                return 0;
        });

        Lua_helper.add_callback(lua,"getActorAlpha", function(id:String) {
            if(getActorByName(id) != null)
                return getActorByName(id).alpha;
            else
                return 0.0;
        });

        Lua_helper.add_callback(lua,"getActorAngle", function(id:String) {
            if(getActorByName(id) != null)
                return getActorByName(id).angle;
            else
                return 0.0;
        });

        Lua_helper.add_callback(lua,"getActorX", function (id:String) {
            if(getActorByName(id) != null)
                return getActorByName(id).x;
            else
                return 0.0;
        });

        Lua_helper.add_callback(lua,"getActorY", function (id:String) {
            if(getActorByName(id) != null)
                return getActorByName(id).y;
            else
                return 0.0;
        });

        Lua_helper.add_callback(lua,"setWindowPos",function(x:Int,y:Int) {
            Application.current.window.move(x, y);
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

        Lua_helper.add_callback(lua,"setCanFullscreen",function(can_Fullscreen:Bool) {
            PlayState.instance.canFullscreen = can_Fullscreen;
        });

        Lua_helper.add_callback(lua,"changeDadCharacter", function (character:String) {
            var oldDad = PlayState.dad;
            PlayState.instance.removeObject(oldDad);
            
            var dad = new Character(100, 100, character);
            PlayState.dad = dad;

            if(dad.otherCharacters == null)
            {
                if(dad.coolTrail != null)
                    PlayState.instance.add(dad.coolTrail);
    
                PlayState.instance.add(dad);
            }
            else
            {
                for(character in dad.otherCharacters)
                {
                    if(character.coolTrail != null)
                        PlayState.instance.add(character.coolTrail);
    
                    PlayState.instance.add(character);
                }
            }

            lua_Sprites.remove("dad");

            oldDad.kill();
            oldDad.destroy();

            lua_Sprites.set("dad", dad);

            @:privateAccess
            {
                var oldIcon = PlayState.instance.iconP2;
                var bar = PlayState.instance.healthBar;
                
                PlayState.instance.removeObject(oldIcon);
                oldIcon.kill();
                oldIcon.destroy();

                PlayState.instance.iconP2 = new HealthIcon(dad.icon, false);
                PlayState.instance.iconP2.y = PlayState.instance.healthBar.y - (PlayState.instance.iconP2.height / 2);
                PlayState.instance.iconP2.cameras = [PlayState.instance.camHUD];
                PlayState.instance.add(PlayState.instance.iconP2);

                bar.createFilledBar(dad.barColor, PlayState.boyfriend.barColor);
                bar.updateFilledBar();

                PlayState.instance.stage.setCharOffsets();
            }
        });

        Lua_helper.add_callback(lua,"changeBoyfriendCharacter", function (character:String) {
            var oldBF = PlayState.boyfriend;
            PlayState.instance.removeObject(oldBF);
            
            var boyfriend = new Boyfriend(770, 450, character);
            PlayState.boyfriend = boyfriend;

            if(boyfriend.otherCharacters == null)
            {
                if(boyfriend.coolTrail != null)
                    PlayState.instance.add(boyfriend.coolTrail);
    
                PlayState.instance.add(boyfriend);
            }
            else
            {
                for(character in boyfriend.otherCharacters)
                {
                    if(character.coolTrail != null)
                        PlayState.instance.add(character.coolTrail);
    
                    PlayState.instance.add(character);
                }
            }

            lua_Sprites.remove("boyfriend");

            oldBF.kill();
            oldBF.destroy();

            lua_Sprites.set("boyfriend", boyfriend);

            @:privateAccess
            {
                var oldIcon = PlayState.instance.iconP1;
                var bar = PlayState.instance.healthBar;
                
                PlayState.instance.removeObject(oldIcon);
                oldIcon.kill();
                oldIcon.destroy();

                PlayState.instance.iconP1 = new HealthIcon(boyfriend.icon, false);
                PlayState.instance.iconP1.y = PlayState.instance.healthBar.y - (PlayState.instance.iconP1.height / 2);
                PlayState.instance.iconP1.cameras = [PlayState.instance.camHUD];
                PlayState.instance.iconP1.flipX = true;
                PlayState.instance.add(PlayState.instance.iconP1);

                bar.createFilledBar(PlayState.dad.barColor, boyfriend.barColor);
                bar.updateFilledBar();

                PlayState.instance.stage.setCharOffsets();
            }
        });

        // scroll speed

        var original_Scroll_Speed = PlayState.SONG.speed;

        Lua_helper.add_callback(lua,"getBaseScrollSpeed",function() {
            return original_Scroll_Speed;
        });

        Lua_helper.add_callback(lua,"getScrollSpeed",function() {
            return PlayState.SONG.speed;
        });

        Lua_helper.add_callback(lua,"setScrollSpeed",function(speed:Float) {
            PlayState.SONG.speed = speed;
        });

        // sounds

        Lua_helper.add_callback(lua, "createSound", function(id:String, file_Path:String, library:String, ?looped:Bool = false) {
            if(lua_Sounds.get(id) == null)
            {
                lua_Sounds.set(id, new FlxSound().loadEmbedded(Paths.sound(file_Path, library), looped));

                FlxG.sound.list.add(lua_Sounds.get(id));
            }
            else
                trace("Error! Sound " + id + " already exists! Try another sound name!");
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

        Lua_helper.add_callback(lua,"setSoundVolume", function(id:String, volume:Float) {
            if(lua_Sounds.get(id) != null)
                lua_Sounds.get(id).volume = volume;
        });

        Lua_helper.add_callback(lua,"getSoundTime", function(id:String) {
            if(lua_Sounds.get(id) != null)
                return lua_Sounds.get(id).time;

            return 0;
        });

        // tweens
        
        Lua_helper.add_callback(lua,"tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
            FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });
                        
        Lua_helper.add_callback(lua,"tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance, {defaultCamZoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });
                        
        Lua_helper.add_callback(lua,"tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance, {defaultHudCamZoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPos", function(id:String, toX:Int, toY:Int, time:Float, ?onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.quintInOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
            FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });
                        
        Lua_helper.add_callback(lua,"tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenCameraZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance, {defaultCamZoom:toZoom}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });
                        
        Lua_helper.add_callback(lua,"tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance, {defaultHudCamZoom:toZoom}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
            FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });
                        
        Lua_helper.add_callback(lua,"tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenCameraZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance, {defaultCamZoom:toZoom}, time, {ease: FlxEase.quintInOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });
                        
        Lua_helper.add_callback(lua,"tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
            FlxTween.tween(PlayState.instance, {defaultHudCamZoom:toZoom}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,["camera"]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {ease: FlxEase.circIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenFadeOut", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
            if(getActorByName(id) != null)
                FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {ease: FlxEase.circOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {callLua(onComplete,[id]);}}});
        });

        Lua_helper.add_callback(lua,"tweenActorColor", function(id:String, r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int, time:Float, onComplete:String = "") {
            var actor = getActorByName(id);

            if(getActorByName(id) != null)
            {
                FlxTween.color(
                    actor,
                    time,
                    FlxColor.fromRGB(r1, g1, b1, 255),
                    FlxColor.fromRGB(r2, g2, b2, 255),
                    {
                        ease: FlxEase.circIn,
                        onComplete: function(flxTween:FlxTween) {
                            if (onComplete != '' && onComplete != null)
                            {
                                callLua(onComplete,[id]);
                            }
                        }
                    }
                );
            }
        });

        // properties

        Lua_helper.add_callback(lua,"setProperty", function(object:String, property:String, value:Dynamic) {
            if(object != "")
            {
                @:privateAccess
                if(Reflect.getProperty(PlayState.instance, object) != null)
                    Reflect.setProperty(Reflect.getProperty(PlayState.instance, object), property, value);
                else
                    Reflect.setProperty(Reflect.getProperty(PlayState, object), property, value);
            }
            else
            {
                @:privateAccess
                if(Reflect.getProperty(PlayState.instance, property) != null)
                    Reflect.setProperty(PlayState.instance, property, value);
                else
                    Reflect.setProperty(PlayState, property, value);
            }
        });

        Lua_helper.add_callback(lua,"getProperty", function(object:String, property:String) {
            if(object != "")
            {
                @:privateAccess
                if(Reflect.getProperty(PlayState.instance, object) != null)
                    return Reflect.getProperty(Reflect.getProperty(PlayState.instance, object), property);
                else
                    return Reflect.getProperty(Reflect.getProperty(PlayState, object), property);
            }
            else
            {
                @:privateAccess
                if(Reflect.getProperty(PlayState.instance, property) != null)
                    return Reflect.getProperty(PlayState.instance, property);
                else
                    return Reflect.getProperty(PlayState, property);
            }
        });

        Lua_helper.add_callback(lua, "getPropertyFromClass", function(className:String, variable:String) {
            @:privateAccess
            {
                var variablePaths = variable.split(".");

                if(variablePaths.length > 1)
                {
                    var selectedVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), variablePaths[0]);

                    for (i in 1...variablePaths.length-1)
                    {
                        selectedVariable = Reflect.getProperty(selectedVariable, variablePaths[i]);
                    }

                    return Reflect.getProperty(selectedVariable, variablePaths[variablePaths.length - 1]);
                }

                return Reflect.getProperty(Type.resolveClass(className), variable);
            }
		});

		Lua_helper.add_callback(lua, "setPropertyFromClass", function(className:String, variable:String, value:Dynamic) {
            @:privateAccess
            {
                var variablePaths:Array<String> = variable.split('.');

                if(variablePaths.length > 1)
                {
                    var selectedVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), variablePaths[0]);

                    for (i in 1...variablePaths.length-1)
                    {
                        selectedVariable = Reflect.getProperty(selectedVariable, variablePaths[i]);
                    }

                    return Reflect.setProperty(selectedVariable, variablePaths[variablePaths.length - 1], value);
                }

                return Reflect.setProperty(Type.resolveClass(className), variable, value);
            }
		});

        // song stuff

        Lua_helper.add_callback(lua,"setSongPosition", function(position:Float) {
            Conductor.songPosition = position;
            setVar('songPos', Conductor.songPosition);
        });

        Lua_helper.add_callback(lua,"stopSong", function() {
            @:privateAccess
            {
                PlayState.instance.paused = true;

                FlxG.sound.music.volume = 0;
                PlayState.instance.vocals.volume = 0;
    
                PlayState.instance.notes.clear();
                PlayState.instance.remove(PlayState.instance.notes);

                FlxG.sound.music.time = 0;
                PlayState.instance.vocals.time = 0;
    
                Conductor.songPosition = 0;
                PlayState.songMultiplier = 0;

                Conductor.recalculateStuff(PlayState.songMultiplier);

                #if cpp
                lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, PlayState.songMultiplier);

                if(PlayState.instance.vocals.playing)
                    lime.media.openal.AL.sourcef(PlayState.instance.vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, PlayState.songMultiplier);
                #end

                PlayState.instance.stopSong = true;
            }

            return true;
        });

        Lua_helper.add_callback(lua,"endSong", function() {
            @:privateAccess
            {
                FlxG.sound.music.time = FlxG.sound.music.length;
                PlayState.instance.vocals.time = FlxG.sound.music.length;

                PlayState.instance.health = 500000;
                PlayState.instance.invincible = true;

                PlayState.instance.stopSong = false;

                PlayState.instance.resyncVocals();
            }

            return true;
        });

        Lua_helper.add_callback(lua,"getCharFromEvent", function(eventId:String) {
            switch(eventId.toLowerCase())
            {
                case "girlfriend" | "gf" | "player3" | "2":
                    return "girlfriend";
                case "dad" | "opponent" | "player2" | "1":
                    return "dad";
                case "bf" | "boyfriend" | "player" | "player1" | "0":
                    return "boyfriend";
            }
    
            return eventId;
        });

        // shader bullshit

        Lua_helper.add_callback(lua,"setActor3DShader", function(id:String, ?speed:Float = 3, ?frequency:Float = 10, ?amplitude:Float = 0.25) {
            var actor = getActorByName(id);

            if(actor != null)
            {
                var funnyShader:shaders.Shaders.ThreeDEffect = shaders.Shaders.newEffect("3d");
                funnyShader.waveSpeed = speed;
                funnyShader.waveFrequency = frequency;
                funnyShader.waveAmplitude = amplitude;
                lua_Shaders.set(id, funnyShader);
                
                actor.shader = funnyShader.shader;
            }
        });
        
        Lua_helper.add_callback(lua,"setActorNoShader", function(id:String) {
            var actor = getActorByName(id);

            if(actor != null)
            {
                lua_Shaders.remove(id);
                actor.shader = null;
            }
        });

        Lua_helper.add_callback(lua,"updateRating", function() {
            PlayState.instance.updateRating();
        });

        executeState("onCreate", []);
        executeState("createLua", []);
    }

    public function setupTheShitCuzPullRequestsSuck()
    {
        lua_Sprites.set("boyfriend", PlayState.boyfriend);
        lua_Sprites.set("girlfriend", PlayState.gf);
        lua_Sprites.set("dad", PlayState.dad);

        lua_Characters.set("boyfriend", PlayState.boyfriend);
        lua_Characters.set("girlfriend", PlayState.gf);
        lua_Characters.set("dad", PlayState.dad);

        lua_Sounds.set("Inst", FlxG.sound.music);
        @:privateAccess
        lua_Sounds.set("Voices", PlayState.instance.vocals);

        @:privateAccess
        for(object in PlayState.instance.stage.stage_Objects)
        {
            lua_Sprites.set(object[0], object[1]);
        }

        if(PlayState.dad.otherCharacters != null)
        {
            for(char in 0...PlayState.dad.otherCharacters.length)
            {
                lua_Sprites.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
                lua_Characters.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
            }
        }

        if(PlayState.boyfriend.otherCharacters != null)
        {
            for(char in 0...PlayState.boyfriend.otherCharacters.length)
            {
                lua_Sprites.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
                lua_Characters.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
            }
        }

        if(PlayState.gf.otherCharacters != null)
        {
            for(char in 0...PlayState.gf.otherCharacters.length)
            {
                lua_Sprites.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
                lua_Characters.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
            }
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
		var result:Any = null;

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua,-1);
		Lua.pop(lua, 1);

		if (result == null)
		    return null;
		else
        {
		    var new_result = convert(result, type);
		    return new_result;
		}
	}

    public function executeState(name,args:Array<Dynamic>)
    {
        return Lua.tostring(lua, callLua(name, args));
    }

    public static function createModchartUtilities(?path:Null<String>):ModchartUtilities
    {
        return new ModchartUtilities(path);
    }

    function cameraFromString(cam:String):FlxCamera
    {
		switch(cam.toLowerCase())
        {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
		}

		return PlayState.instance.camGame;
	}

    function blendModeFromString(blend:String):BlendMode
    {
		switch(blend.toLowerCase().trim())
        {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}

		return NORMAL;
	}
}
#end
