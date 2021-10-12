package modding;

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
    public static var lua:State = null;

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
        lua_Sprites = [
            'boyfriend' => PlayState.boyfriend,
            'girlfriend' => PlayState.gf,
            'dad' => PlayState.dad,
        ];

        lua_Characters = [
            'boyfriend' => PlayState.boyfriend,
            'girlfriend' => PlayState.gf,
            'dad' => PlayState.dad,
        ];
    
        lua_Sounds = [];

        lua = LuaL.newstate();
        LuaL.openlibs(lua);

        trace("lua version: " + Lua.version());
        trace("LuaJIT version: " + Lua.versionJIT());

        Lua.init_callbacks(lua);

        var path = PolymodAssets.getPath(Paths.lua("modcharts/" + PlayState.SONG.modchartPath));

        var result = LuaL.dofile(lua, path); // execute le file

        if (result != 0)
        {
            Application.current.window.alert("lua COMPILE ERROR:\n" + Lua.tostring(lua,result),"Leather Engine Modcharts");
            //FlxG.switchState(new MainMenuState());
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

        Lua_helper.add_callback(lua,"makeSprite", function(id:String, filename:String, x:Float, y:Float, size:Float) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:FlxSprite = new FlxSprite(x, y);

                if(Assets.exists(Paths.image(PlayState.SONG.stage + "/" + filename, "stages"), IMAGE))
                    Sprite.loadGraphic(Paths.image(PlayState.SONG.stage + "/" + filename, "stages"));
                else
                    Sprite.loadGraphic(Paths.imageSYS(PlayState.SONG.stage + "/" + filename, "stages"), false, 0, 0, false, PlayState.SONG.stage + "/" + filename);

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
    
                lua_Sprites.set(id, Sprite);
    
                PlayState.instance.add(Sprite);
            }
            else
                Application.current.window.alert("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
        });

        Lua_helper.add_callback(lua, "getProperty", getPropertyByName);

        Lua_helper.add_callback(lua,"makeAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float) {
            if(!lua_Sprites.exists(id))
            {
                var Sprite:FlxSprite = new FlxSprite(x, y);

                if(Assets.exists(Paths.image(PlayState.SONG.stage + "/" + filename, "stages"), IMAGE))
                    Sprite.frames = Paths.getSparrowAtlas(PlayState.SONG.stage + "/" + filename, "stages");
                else
                    Sprite.frames = Paths.getSparrowAtlasSYS(PlayState.SONG.stage + "/" + filename, "stages");

                Sprite.setGraphicSize(Std.int(Sprite.width * size));
    
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

        // hud/camera

        Lua_helper.add_callback(lua,"setHudAngle", function (x:Float) {
            PlayState.instance.camHUD.angle = x;
        });

        Lua_helper.add_callback(lua,"getHealth", function() {
            return PlayState.instance.health;
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


        Lua_helper.add_callback(lua,"setRenderedNoteAngle", function(angle:Float, id:Int) {
            PlayState.instance.notes.members[id].modifiedByLua = true;
            PlayState.instance.notes.members[id].angle = angle;
        });

        Lua_helper.add_callback(lua,"setActorX", function(x:Int,id:String) {
            getActorByName(id).x = x;
        });

        Lua_helper.add_callback(lua,"setActorPos", function(x:Int,y:Int,id:String) {
            var actor = getActorByName(id);
            actor.x = x;
            actor.y = y;
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

        Lua_helper.add_callback(lua,"addActorAnimation", function(id:String,prefix:String,anim:String,fps:Int = 30, looped:Bool = true) {
            getActorByName(id).animation.addByPrefix(prefix, anim, fps, looped);
        });
        
        Lua_helper.add_callback(lua,"playActorAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false) {
            getActorByName(id).playAnim(anim, force, reverse);
        });

        Lua_helper.add_callback(lua,"setActorAlpha", function(alpha:Float,id:String) {
            getActorByName(id).alpha = alpha;
        });

        Lua_helper.add_callback(lua,"setActorColor", function(id:String,r:Int,g:Int,b:Int,alpha:Int = 255) {
            getActorByName(id).color = FlxColor.fromRGB(r, g, b, alpha);
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

        Lua_helper.add_callback(lua,"tweenActorColor", function(id:String, r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int, time:Float, onComplete:String) {
            var actor = getActorByName(id);

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
        });

        // default strums

        for (i in 0...PlayState.strumLineNotes.length) {
            var member = PlayState.strumLineNotes.members[i];
            trace(PlayState.strumLineNotes.members[i].x + " " + PlayState.strumLineNotes.members[i].y + " " + PlayState.strumLineNotes.members[i].angle + " | strum" + i);

            setVar("defaultStrum" + i + "X", Math.floor(member.x));
            setVar("defaultStrum" + i + "Y", Math.floor(member.y));
            setVar("defaultStrum" + i + "Angle", Math.floor(member.angle));

            trace("Adding strum" + i);
        }

        @:privateAccess
        for(object in PlayState.instance.stage.stage_Objects)
        {
            if(!lua_Sprites.exists(object[0]))
                lua_Sprites.set(object[0], object[1]);
            else
                trace("THERE IS ALREADY AN OBJECT WITH THE NAME " + object[0]);
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