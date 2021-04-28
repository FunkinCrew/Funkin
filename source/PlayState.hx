package;

import flixel.ui.FlxButton.FlxTypedButton;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import openfl.geom.Matrix;
import flixel.FlxGame;
import flixel.FlxObject;
import DifficultyIcons;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxState;
import flixel.FlxSubState;
import flash.display.BitmapData;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import lime.system.System;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;

#end
#if windows
import llua.Lua;
import llua.LuaL;
import llua.Convert;
import llua.State;
#end
import tjson.TJSON;
using StringTools;
typedef LuaAnim = {
	var prefix : String;
	@:optional var indices: Array<Int>;
	var name : String;
	@:optional var fps : Int;
	@:optional var loop : Bool;
}
enum abstract DisplayLayer(Int) from Int to Int {
	var BEHIND_GF = 1;
	var BEHIND_BF = 1 << 1;
	var BEHIND_DAD = 1 << 2;
	var BEHIND_ALL = BEHIND_GF | BEHIND_BF | BEHIND_DAD;
}
class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var defaultPlaylistLength = 0;

	var halloweenLevel:Bool = false;

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;
	private var enemyStrums:FlxTypedGroup<FlxSprite>;
	private var camZooming:Bool = false;
	private var curSong:String = "";
	private var strumming2:Array<Bool> = [false, false, false, false];

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;


	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;
	// this'll work... right?
	var backgroundgroup:FlxTypedGroup<BeatSprite>;
	var foregroundgroup:FlxTypedGroup<BeatSprite>;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();

	var talking:Bool = true;
	var songScore:Int = 0;
	var trueScore:Int = 0;
	var scoreTxt:FlxText;
	var healthTxt:FlxText;
	var accuracyTxt:FlxText;
	var difficTxt:FlxText;
	public static var campaignScore:Int = 0;
	public static var campaignAccuracy:Float = 0;
	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var bfoffset = [0.0, 0.0];
	var gfoffset = [0.0, 0.0];
	var dadoffset = [0.0, 0.0];
	var inCutscene:Bool = false;
	var alwaysDoCutscenes = false;
	var fullComboMode:Bool = false;
	var perfectMode:Bool = false;
	var practiceMode:Bool = false;
	var healthGainModifier:Float = 0;
	var healthLossModifier:Float = 0;
	var supLove:Bool = false;
	var poisonExr:Bool = false;
	var poisonPlus:Bool = false;
	var beingPoisioned:Bool = false;
	var poisonTimes:Int = 0;
	var flippedNotes:Bool = false;
	var noteSpeed:Float = 0.45;
	var practiceDied:Bool = false;
	var practiceDieIcon:HealthIcon;
	private var regenTimer:FlxTimer;
	var sickFastTimer:FlxTimer;
	var accelNotes:Bool = false;
	var notesHit:Float = 0;
	var notesPassing:Int = 0;
	var vnshNotes:Bool = false;
	var invsNotes:Bool = false;
	var snakeNotes:Bool = false;
	var snekNumber:Float = 0;
	var drunkNotes:Bool = false;
	var alcholTimer:FlxTimer;
	var alcholNumber:Float = 0;
	var inALoop:Bool = false;
	var useVictoryScreen:Bool = true;
	#if windows
	public var luaStates:Map<String, State> = [];
	function callLua(func_name:String, args:Array<Dynamic>, type:String, uselua:String):Dynamic
	{	
		var result:Any = null;
		Lua.getglobal(luaStates.get(uselua), func_name);

		for (arg in args)
		{
			Convert.toLua(luaStates.get(uselua), arg);
		}
		Lua.call(luaStates.get(uselua), args.length, 1);

		if (result == null)
		{
			return null;
		}
		else
		{
			return convert(result, type);
		}
	}
	function callAllLua(func_name:String, args:Array<Dynamic>, type:String) {
		for (key in luaStates.keys()) {
			callLua(func_name, args,type,key);
		}
	}
	function setAllVar(var_name:String, object:Dynamic) {
		for (keys in luaStates.keys()) {
			setVar(var_name, object, keys);
		}
	}

	function getType(l, type):Any
	{
		return switch Lua.type(l, type)
		{
			case t if (t == Lua.LUA_TNIL): null;
			case t if (t == Lua.LUA_TNUMBER): Lua.tonumber(l, type);
			case t if (t == Lua.LUA_TSTRING): (Lua.tostring(l, type) : String);
			case t if (t == Lua.LUA_TBOOLEAN): Lua.toboolean(l, type);
			case t: throw 'you don goofed up. lua type error ($t)';
		}
	}
	function makeLuaState(uselua:String, path:String, filename:String) {
		trace('opening a lua state (because we are cool :))');
		luaStates.set(uselua, LuaL.newstate());
		LuaL.openlibs(luaStates.get(uselua));
		trace("Lua version: " + Lua.version());
		trace("LuaJIT version: " + Lua.versionJIT());
		Lua.init_callbacks(luaStates.get(uselua));

		var result = LuaL.dofile(luaStates.get(uselua), path + filename); // execute le file

		if (result != 0)
		{
			luaStates.remove(uselua);
			FlxG.switchState(new MainMenuState());
		}

		// get some fukin globals up in here bois
		setVar("BEHIND_GF", BEHIND_GF, uselua);
		setVar("BEHIND_BF", BEHIND_BF, uselua);
		setVar("BEHIND_DAD", BEHIND_DAD, uselua);
		setVar("BEHIND_ALL", BEHIND_ALL, uselua);
		setVar("BEHIND_NONE", 0, uselua);
		setVar("STATIC_IMAGE", 0, uselua);
		setVar("SPARROW_SHEET", 1, uselua);
		setVar("PACKER_SHEET", 2, uselua);
		trace(PlayState.SONG.isMoody);
		setVar("isMoody", PlayState.SONG.isMoody, uselua);
		setVar("difficulty", storyDifficulty, uselua);
		setVar("bpm", Conductor.bpm, uselua);
		setVar("scrollspeed", PlayState.SONG.speed, uselua);
		setVar("fpsCap", FlxG.save.data.fpsCap, uselua);
		setVar("downscroll", FlxG.save.data.downscroll, uselua);

		setVar("curStep", 0, uselua);
		setVar("curBeat", 0, uselua);
		setVar("crochet", Conductor.stepCrochet, uselua);
		setVar("safeZoneOffset", Conductor.safeZoneOffset, uselua);

		setVar("hudZoom", camHUD.zoom, uselua);
		setVar("cameraZoom", FlxG.camera.zoom, uselua);

		setVar("cameraAngle", FlxG.camera.angle, uselua);
		setVar("camHudAngle", camHUD.angle, uselua);

		setVar("followXOffset", 0, uselua);
		setVar("followYOffset", 0, uselua);

		setVar("showOnlyStrums", false, uselua);
		setVar("strumLine1Visible", true, uselua);
		setVar("strumLine2Visible", true, uselua);

		setVar("screenWidth", FlxG.width, uselua);
		setVar("screenHeight", FlxG.height, uselua);
		setVar("hudWidth", camHUD.width, uselua);
		setVar("hudHeight", camHUD.height, uselua);

		setVar("mustHit", false, uselua);

		setVar("strumLineY", strumLine.y, uselua);

		// callbacks

		// sprites

		trace(Lua_helper.add_callback(luaStates.get(uselua), "makeSprite", function(spritePath:String, toBeCalled:String, drawBehind:DisplayLayer, doAnim:Int)
		{
			trace("making sprite");
			#if sys
			var sprite:FlxSprite = new FlxSprite(0, 0);
			if (doAnim == 0)
			{
				sprite.loadGraphic(path + spritePath + ".png");
			}
			else if (doAnim == 1)
			{
				sprite.frames = FlxAtlasFrames.fromSparrow(
					path
					+ spritePath
					+ ".png",
					path
					+ spritePath
					+ ".xml");
			}
			else
			{
				sprite.frames = FlxAtlasFrames.fromSpriteSheetPacker(
					path
					+ spritePath
					+ ".png",
					path
					+ spritePath
					+ ".txt");
			}
			// you usually want this on, make it default.
			sprite.antialiasing = true;
			luaSprites.set(toBeCalled, sprite);
			// and I quote:
			// shitty layering but it works!
			if (drawBehind & BEHIND_GF != 0)
			{
				remove(gf);
			}
			if (drawBehind & BEHIND_DAD != 0)
				remove(dad);
			if (drawBehind & BEHIND_BF != 0)
				remove(boyfriend);
			
			trace(":)");
			add(sprite);
			if (drawBehind & BEHIND_GF != 0)
			{
				add(gf);
			}
			if (drawBehind & BEHIND_DAD != 0)
				add(dad);
			if (drawBehind & BEHIND_BF != 0)
				add(boyfriend);
			
			#end
			return toBeCalled;
		}));

		Lua_helper.add_callback(luaStates.get(uselua), "destroySprite", function(id:String)
		{
			var sprite = luaSprites.get(id);
			if (sprite == null)
				return false;
			remove(sprite);
			return true;
		});
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addTimer", function(func:String, time:Float)
		{
			new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				callLua(func, [], null, uselua);
			});
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "bitwiseor", function(a:Int, b:Int)
		{
			return a | b;
		}));

		// hud/camera
		trace(Lua_helper.add_callback(luaStates.get(uselua), "trace", function(value:Dynamic)
		{
			trace(value);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "elapsed", function()
		{
			return FlxG.elapsed;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setHudPosition", function(x:Int, y:Int)
		{
			camHUD.x = x;
			camHUD.y = y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "newArray", function(id:String)
		{
			luaArray.set(id, []);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "pushArray", function(value:Any, id:String)
		{
			luaArray.get(id).push(value);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "popArray", function(id:String)
		{
			return luaArray.get(id).pop();
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "newRangeArray", function(min:Int, max:Int, id:String)
		{
			var coolarray:Array<Any> = [];
			// keep lua inclusive
			for (i in min...(max + 1))
			{
				coolarray.push(i);
			}
			luaArray.set(id, coolarray);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorFollowCam", function(x:Int, y:Int, id:String)
		{
			getActorByName(id).followCamX = x;
			getActorByName(id).followCamY = y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorFollowCamX", function(id:String)
		{
			return getActorByName(id).followCamX;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "makeActorPixel", function(id:String)
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * 6));
			getActorByName(id).updateHitbox();
			getActorByName(id).antialiasing = false;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorFollowCamY", function(id:String)
		{
			return getActorByName(id).followCamY;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addActorAnimationPrefix", function(prefix:String, name:String, fps:Int, loop:Bool, id:String)
		{
			getActorByName(id).animation.addByPrefix(name, prefix, fps, loop);
			trace(getActorByName(id).animation);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addActorAnimationIndices", function(prefix:String, name:String, indices:String, fps:Int, id:String)
		{
			trace(luaArray.get(indices));
			getActorByName(id).animation.addByIndices(name, prefix, luaArray.get(indices), "", fps, false);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addActorAnimation",
			function(name:String, indices:String, fps:Int, loop:Bool, id:String)
			{
				trace(luaArray.get(indices));
			getActorByName(id).animation.add(name, luaArray.get(indices), fps, loop);
			}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "playActorAnimation", function(animation:String, force:Bool, id:String)
		{
			trace(animation);
			getActorByName(id).animation.play(animation, force);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "playCharacterAnimation", function(animation:String, force:Bool, id:String)
		{
			getActorByName(id).playAnim(animation, force);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getHudX", function()
		{
			return camHUD.x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getHudY", function()
		{
			return camHUD.y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setCamPosition", function(x:Int, y:Int)
		{
			FlxG.camera.x = x;
			FlxG.camera.y = y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "playSound", function(filename1:String)
		{
			FlxG.sound.play(path + filename1 + '.ogg');
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "playStoredSound", function(force:Bool, id:String)
		{
			luaSound.get(id).play(force);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getSoundPlaying", function(id:String)
		{
			return luaSound.get(id).playing;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getCameraX", function()
		{
			return FlxG.camera.x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addSoundToList", function(filename1:String, tobecalled:String)
		{
			luaSound.set(tobecalled, new FlxSound().loadEmbedded(path + filename1 + '.ogg'));
			FlxG.sound.list.add(luaSound.get(tobecalled));
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getSoundTime", function(id:String)
		{
			return luaSound.get(id).time;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getCameraY", function()
		{
			return FlxG.camera.y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setCamZoom", function(zoomAmount:Float)
		{
			FlxG.camera.zoom = zoomAmount;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setDefaultZoom", function(zoomAmount:Float)
		{
			FlxG.camera.zoom = zoomAmount;
			defaultCamZoom = zoomAmount;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setHudZoom", function(zoomAmount:Float)
		{
			camHUD.zoom = zoomAmount;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorX", function(x:Int, id:String)
		{
			getActorByName(id).x = x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorVelocityX", function(x:Int, id:String)
		{
			getActorByName(id).velocity.x = x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorAlpha", function(alpha:Int, id:String)
		{
			getActorByName(id).alpha = alpha;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNotes", function()
		{
			return notes.length;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteX", function(id:Int)
		{
			return notes.members[id].x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteY", function(id:Int)
		{
			return notes.members[id].y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteType", function(id:Int)
		{
			return notes.members[id].noteData;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "isSustain", function(id:Int)
		{
			return notes.members[id].isSustainNote;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "isParentSustain", function(id:Int)
		{
			return notes.members[id].prevNote.isSustainNote;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteParentX", function(id:Int)
		{
			return notes.members[id].prevNote.x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteParentY", function(id:Int)
		{
			return notes.members[id].prevNote.y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteHit", function(id:Int)
		{
			return notes.members[id].mustPress;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteCalcX", function(id:Int)
		{
			if (notes.members[id].mustPress)
				return playerStrums.members[Math.floor(Math.abs(notes.members[id].noteData))].x;
			return strumLineNotes.members[Math.floor(Math.abs(notes.members[id].noteData))].x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "anyNotes", function()
		{
			return notes.members.length != 0;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteStrumtime", function(id:Int)
		{
			return notes.members[id].strumTime;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteScaleX", function(id:Int)
		{
			return notes.members[id].scale.x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNotePos", function(x:Float, y:Float, id:Int)
		{
			if (notes.members[id] == null)
				throw('error! you cannot set a rendered notes position when it doesnt exist! ID: ' + id);
			else
			{
				notes.members[id].modifiedByLua = true;
				notes.members[id].x = x;
				notes.members[id].y = y;
			}
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteAlpha", function(alpha:Float, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].alpha = alpha;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteScale", function(scale:Float, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].setGraphicSize(Std.int(notes.members[id].width * scale));
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteScale", function(scaleX:Int, scaleY:Int, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].setGraphicSize(scaleX, scaleY);
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteWidth", function(id:Int)
		{
			return notes.members[id].width;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteAngle", function(angle:Float, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].angle = angle;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorY", function(y:Int, id:String)
		{
			getActorByName(id).y = y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorVelocityY", function(y:Int, id:String)
		{
			getActorByName(id).velocity.y = y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorAngle", function(angle:Int, id:String)
		{
			getActorByName(id).angle = angle;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorScale", function(scale:Float, id:String)
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scale));
			getActorByName(id).updateHitbox();
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorScaleMember", function(scale:Float, id:String)
		{
			trace(getActorByName(id).scale.x);
			getActorByName(id).scale.set(scale, scale);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getScaleX", function(id:String)
		{
			return getActorByName(id).scale.x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getScaleY", function(id:String)
		{
			return getActorByName(id).scale.y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorAntialias", function(antialias:Bool, id:String)
		{
			getActorByName(id).antialiasing = antialias;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorScrollFactor", function(factorx:Float, factory:Float, id:String)
		{
			getActorByName(id).scrollFactor.set(factorx, factory);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorWidth", function(id:String)
		{
			return getActorByName(id).width;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorHeight", function(id:String)
		{
			return getActorByName(id).height;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorAlpha", function(id:String)
		{
			return getActorByName(id).alpha;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorAngle", function(id:String)
		{
			return getActorByName(id).angle;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorX", function(id:String)
		{
			return getActorByName(id).x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorY", function(id:String)
		{
			return getActorByName(id).y;
		}));

		// tweens

		Lua_helper.add_callback(luaStates.get(uselua), "tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});
		Lua_helper.add_callback(luaStates.get(uselua), "shakeCamera", function(intensity:Float,time:Float, onComplete:String)
		{
			FlxG.camera.shake(intensity,time,function() {
				if (onComplete != '' && onComplete != null)
				{
					callLua(onComplete, ["camera"], null, uselua);
				}
			});
		});
		Lua_helper.add_callback(luaStates.get(uselua), "tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(FlxG.camera, {zoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(camHUD, {zoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenPos", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenFadeIn", function(id:String, toAlpha:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
				ease: FlxEase.circIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenFadeOut", function(id:String, toAlpha:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
				ease: FlxEase.circOut,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});


		for (i in 0...strumLineNotes.length)
		{
			var member = strumLineNotes.members[i];
			trace(strumLineNotes.members[i].x + " " + strumLineNotes.members[i].y + " " + strumLineNotes.members[i].angle + " | strum" + i);
			// setVar("strum" + i + "X", Math.floor(member.x));
			setVar("defaultStrum" + i + "X", Math.floor(member.x), uselua);
			// setVar("strum" + i + "Y", Math.floor(member.y));
			setVar("defaultStrum" + i + "Y", Math.floor(member.y), uselua);
			// setVar("strum" + i + "Angle", Math.floor(member.angle));
			setVar("defaultStrum" + i + "Angle", Math.floor(member.angle), uselua);
			trace("Adding strum" + i);
		}

		trace('calling start function');

		trace('return: ' + Lua.tostring(luaStates.get(uselua), callLua('start', [PlayState.SONG.song], null, uselua)));
	}
	function getReturnValues(l)
	{
		var lua_v:Int;
		var v:Any = null;
		while ((lua_v = Lua.gettop(l)) != 0)
		{
			var type:String = getType(l, lua_v);
			v = convert(lua_v, type);
			Lua.pop(l, 1);
		}
		return v;
	}

	private function convert(v:Any, type:String):Dynamic
	{ // I didn't write this lol
		if (Std.is(v, String) && type != null)
		{
			var v:String = v;
			if (type.substr(0, 4) == 'array')
			{
				trace("array");
				if (type.substr(4) == 'float')
				{
					var array:Array<String> = v.split(',');
					var array2:Array<Float> = new Array();

					for (vars in array)
					{
						array2.push(Std.parseFloat(vars));
					}

					return array2;
				}
				else if (type.substr(4) == 'int')
				{
					var array:Array<String> = v.split(',');
					var array2:Array<Int> = new Array();

					for (vars in array)
					{
						array2.push(Std.parseInt(vars));
					}

					return array2;
				}
				else
				{
					var array:Array<String> = v.split(',');
					return array;
				}
			}
			else if (type == 'float')
			{
				return Std.parseFloat(v);
			}
			else if (type == 'int')
			{
				return Std.parseInt(v);
			}
			else if (type == 'bool')
			{
				if (v == 'true')
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return v;
			}
		}
		else
		{
			return v;
		}
	}

	function getLuaErrorMessage(l)
	{
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);
		return v;
	}

	public function setVar(var_name:String, object:Dynamic, uselua:String)
	{
		// trace('setting variable ' + var_name + ' to ' + object);
		Lua.pushnumber(luaStates.get(uselua), object);
		Lua.setglobal(luaStates.get(uselua), var_name);
	}

	public function getVar(var_name:String, type:String, uselua:String):Dynamic
	{
		var result:Any = null;

		// trace('getting variable ' + var_name + ' with a type of ' + type);

		Lua.getglobal(luaStates.get(uselua), var_name);
		result = Convert.fromLua(luaStates.get(uselua), -1);
		Lua.pop(luaStates.get(uselua), 1);

		if (result == null)
		{
			return null;
		}
		else
		{
			var result = convert(result, type);
			// trace(var_name + ' result: ' + result);
			return result;
		}
	}

	function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch (id)
		{
			case 'boyfriend':
				return boyfriend;
			case 'girlfriend':
				return gf;
			case 'dad':
				return dad;
		}
		// lua objects or what ever
		if (luaSprites.get(id) == null)
			return strumLineNotes.members[Std.parseInt(id)];
		return luaSprites.get(id);
	}

	public static var luaSprites:Map<String, FlxSprite> = [];
	var luaSound:Map<String, FlxSound> = [];
	var luaArray:Map<String, Array<Any>> = [];
	#end
	override public function create()
	{
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];
		persistentUpdate = true;
		persistentDraw = true;
		alwaysDoCutscenes = OptionsHandler.options.alwaysDoCutscenes;
		useVictoryScreen = !OptionsHandler.options.skipVictoryScreen;
		if (!OptionsHandler.options.skipModifierMenu) {
			fullComboMode = ModifierState.modifiers[1].value;
			perfectMode = ModifierState.modifiers[0].value;
			practiceMode = ModifierState.modifiers[2].value;
			flippedNotes = ModifierState.modifiers[10].value;
			accelNotes= ModifierState.modifiers[13].value;
			vnshNotes = ModifierState.modifiers[14].value;
			invsNotes = ModifierState.modifiers[15].value;
			snakeNotes = ModifierState.modifiers[16].value;
			drunkNotes = ModifierState.modifiers[17].value;
			inALoop = ModifierState.modifiers[18].value;
			if (ModifierState.modifiers[3].value) {
				healthGainModifier += 0.02;
			} else if (ModifierState.modifiers[4].value) {
				healthGainModifier -= 0.01;
			}
			if (ModifierState.modifiers[5].value) {
				healthLossModifier += 0.02;
			} else if (ModifierState.modifiers[6].value) {
				healthLossModifier -= 0.02;
			}
			if (ModifierState.modifiers[11].value)
				noteSpeed = 0.3;
			if (accelNotes) {
				noteSpeed = 0.45;
				trace("accel arrows");
			}


			if (ModifierState.modifiers[12].value)
				noteSpeed = 0.9;
			supLove = ModifierState.modifiers[7].value;
			poisonExr = ModifierState.modifiers[8].value;
			poisonPlus = ModifierState.modifiers[9].value;
		}


		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		backgroundgroup = new FlxTypedGroup<BeatSprite>();
		foregroundgroup  = new FlxTypedGroup<BeatSprite>();
		switch (SONG.song.toLowerCase())
		{
			default:
				// prefer player 1
				if (FileSystem.exists('assets/images/custom_chars/'+SONG.player1+'/'+SONG.song.toLowerCase()+'Dialog.txt')) {
					dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/'+SONG.player1+'/'+SONG.song.toLowerCase()+'Dialog.txt');
				// if no player 1 unique dialog, use player 2
				} else if (FileSystem.exists('assets/images/custom_chars/'+SONG.player2+'/'+SONG.song.toLowerCase()+'Dialog.txt')) {
					dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/'+SONG.player2+'/'+SONG.song.toLowerCase()+'Dialog.txt');
				// if no player dialog, use default
				}	else if (FileSystem.exists('assets/data/'+SONG.song.toLowerCase()+'/dialog.txt')) {
					dialogue = CoolUtil.coolDynamicTextFile('assets/data/'+SONG.song.toLowerCase()+'/dialog.txt');
				} else if (FileSystem.exists('assets/data/'+SONG.song.toLowerCase()+'/dialogue.txt')){
					// nerds spell dialogue properly gotta make em happy
					dialogue = CoolUtil.coolDynamicTextFile('assets/data/' + SONG.song.toLowerCase() + '/dialogue.txt');
				// otherwise, make the dialog an error message
				} else {
					dialogue = [':dad: The game tried to get a dialog file but couldn\'t find it. Please make sure there is a dialog file named "dialog.txt".'];
				}
		}
		#if !windows
		if (SONG.stage == 'spooky')
		{
			curStage = "spooky";
			halloweenLevel = true;

			var hallowTex = FlxAtlasFrames.fromSparrow('assets/images/halloween_bg.png', 'assets/images/halloween_bg.xml');

			halloweenBG = new FlxSprite(-200, -100);
			halloweenBG.frames = hallowTex;
			halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
			halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
			halloweenBG.animation.play('idle');
			halloweenBG.antialiasing = true;
			add(halloweenBG);

			isHalloween = true;
		}
		else if (SONG.stage == 'philly')
		{
			curStage = 'philly';

			var bg:FlxSprite = new FlxSprite(-100).loadGraphic('assets/images/philly/sky.png');
			bg.scrollFactor.set(0.1, 0.1);
			add(bg);

			var city:FlxSprite = new FlxSprite(-10).loadGraphic('assets/images/philly/city.png');
			city.scrollFactor.set(0.3, 0.3);
			city.setGraphicSize(Std.int(city.width * 0.85));
			city.updateHitbox();
			add(city);

			phillyCityLights = new FlxTypedGroup<FlxSprite>();
			add(phillyCityLights);

			for (i in 0...5)
			{
				var light:FlxSprite = new FlxSprite(city.x).loadGraphic('assets/images/philly/win' + i + '.png');
				light.scrollFactor.set(0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				light.antialiasing = true;
				phillyCityLights.add(light);
			}

			var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic('assets/images/philly/behindTrain.png');
			add(streetBehind);

			phillyTrain = new FlxSprite(2000, 360).loadGraphic('assets/images/philly/train.png');
			add(phillyTrain);

			trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
			FlxG.sound.list.add(trainSound);

			// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

			var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic('assets/images/philly/street.png');
			add(street);
		}
		else if (SONG.stage == 'limo')
		{
			curStage = 'limo';
			defaultCamZoom = 0.90;

			var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic('assets/images/limo/limoSunset.png');
			skyBG.scrollFactor.set(0.1, 0.1);
			add(skyBG);

			var bgLimo:FlxSprite = new FlxSprite(-200, 480);
			bgLimo.frames = FlxAtlasFrames.fromSparrow('assets/images/limo/bgLimo.png', 'assets/images/limo/bgLimo.xml');
			bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
			bgLimo.animation.play('drive');
			bgLimo.scrollFactor.set(0.4, 0.4);
			add(bgLimo);

			grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
			add(grpLimoDancers);

			for (i in 0...5)
			{
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}

			var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic('assets/images/limo/limoOverlay.png');
			overlayShit.alpha = 0.5;
			// add(overlayShit);

			// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

			// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

			// overlayShit.shader = shaderBullshit;

			var limoTex = FlxAtlasFrames.fromSparrow('assets/images/limo/limoDrive.png', 'assets/images/limo/limoDrive.xml');

			limo = new FlxSprite(-120, 550);
			limo.frames = limoTex;
			limo.animation.addByPrefix('drive', "Limo stage", 24);
			limo.animation.play('drive');
			limo.antialiasing = true;

			fastCar = new FlxSprite(-300, 160).loadGraphic('assets/images/limo/fastCarLol.png');
			// add(limo);
		}
		else if (SONG.stage == 'mall')
		{
			curStage = 'mall';

			defaultCamZoom = 0.80;

			var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic('assets/images/christmas/bgWalls.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.2, 0.2);
			bg.active = false;
			bg.setGraphicSize(Std.int(bg.width * 0.8));
			bg.updateHitbox();
			add(bg);

			upperBoppers = new FlxSprite(-240, -90);
			upperBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/upperBop.png', 'assets/images/christmas/upperBop.xml');
			upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
			upperBoppers.antialiasing = true;
			upperBoppers.scrollFactor.set(0.33, 0.33);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic('assets/images/christmas/bgEscalator.png');
			bgEscalator.antialiasing = true;
			bgEscalator.scrollFactor.set(0.3, 0.3);
			bgEscalator.active = false;
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);

			var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic('assets/images/christmas/christmasTree.png');
			tree.antialiasing = true;
			tree.scrollFactor.set(0.40, 0.40);
			add(tree);

			bottomBoppers = new FlxSprite(-300, 140);
			bottomBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/bottomBop.png', 'assets/images/christmas/bottomBop.xml');
			bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
			bottomBoppers.antialiasing = true;
			bottomBoppers.scrollFactor.set(0.9, 0.9);
			bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
			bottomBoppers.updateHitbox();
			add(bottomBoppers);

			var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic('assets/images/christmas/fgSnow.png');
			fgSnow.active = false;
			fgSnow.antialiasing = true;
			add(fgSnow);

			santa = new FlxSprite(-840, 150);
			santa.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/santa.png', 'assets/images/christmas/santa.xml');
			santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
			santa.antialiasing = true;
			add(santa);
		}
		else if (SONG.stage == 'mallEvil')
		{
			curStage = 'mallEvil';
			var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic('assets/images/christmas/evilBG.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.2, 0.2);
			bg.active = false;
			bg.setGraphicSize(Std.int(bg.width * 0.8));
			bg.updateHitbox();
			add(bg);

			var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic('assets/images/christmas/evilTree.png');
			evilTree.antialiasing = true;
			evilTree.scrollFactor.set(0.2, 0.2);
			add(evilTree);

			var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic("assets/images/christmas/evilSnow.png");
			evilSnow.antialiasing = true;
			add(evilSnow);
		}
		else if (SONG.stage == 'school')
		{
			curStage = 'school';
			// defaultCamZoom = 0.9;

			var bgSky = new FlxSprite().loadGraphic('assets/images/weeb/weebSky.png');
			bgSky.scrollFactor.set(0.1, 0.1);
			add(bgSky);

			var repositionShit = -200;

			var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic('assets/images/weeb/weebSchool.png');
			bgSchool.scrollFactor.set(0.6, 0.90);
			add(bgSchool);

			var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic('assets/images/weeb/weebStreet.png');
			bgStreet.scrollFactor.set(0.95, 0.95);
			add(bgStreet);

			var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic('assets/images/weeb/weebTreesBack.png');
			fgTrees.scrollFactor.set(0.9, 0.9);
			add(fgTrees);

			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
			var treetex = FlxAtlasFrames.fromSpriteSheetPacker('assets/images/weeb/weebTrees.png', 'assets/images/weeb/weebTrees.txt');
			bgTrees.frames = treetex;
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			add(bgTrees);

			var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
			treeLeaves.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/petals.png', 'assets/images/weeb/petals.xml');
			treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
			treeLeaves.animation.play('leaves');
			treeLeaves.scrollFactor.set(0.85, 0.85);
			add(treeLeaves);

			var widShit = Std.int(bgSky.width * 6);

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));
			fgTrees.setGraphicSize(Std.int(widShit * 0.8));
			treeLeaves.setGraphicSize(widShit);

			fgTrees.updateHitbox();
			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			treeLeaves.updateHitbox();

			bgGirls = new BackgroundGirls(-100, 190);
			bgGirls.scrollFactor.set(0.9, 0.9);

			if (SONG.isMoody)
			{
				bgGirls.getScared();
			}

			bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
			bgGirls.updateHitbox();
			add(bgGirls);
		}
		else if (SONG.stage == 'schoolEvil')
		{
			curStage = 'schoolEvil';

			var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
			var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

			var posX = 400;
			var posY = 200;

			var bg:FlxSprite = new FlxSprite(posX, posY);
			bg.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/animatedEvilSchool.png', 'assets/images/weeb/animatedEvilSchool.xml');
			bg.animation.addByPrefix('idle', 'background 2', 24);
			bg.animation.play('idle');
			bg.scrollFactor.set(0.8, 0.9);
			bg.scale.set(6, 6);
			add(bg);
			trace("schoolEvilComplete");
		}
		else if (SONG.stage == "stage")
		{
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/stagefront.png');
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);

			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/stagecurtains.png');
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);
		}
		#end
		var gfVersion:String = 'gf';

		gfVersion = SONG.gf;
		trace(SONG.gf);
		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		dad = new Character(100, 100, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode )
				{
					camPos.x += 600;
					tweenCamIn();
				}

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 130;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.x += 370;
				camPos.y += 300;
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.x += 370;
				camPos.y += 300;
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.x += 300;
			default:
				dad.x += dad.enemyOffsetX;
				dad.y += dad.enemyOffsetY;
				camPos.x += dad.camOffsetX;
				camPos.y += dad.camOffsetY;
				if (dad.like == "gf") {
					dad.setPosition(gf.x, gf.y);
					gf.visible = false;
					if (isStoryMode)
					{
						camPos.x += 600;
						tweenCamIn();
					}
				}
		}



		boyfriend = new Boyfriend(770, 450, SONG.player1);
		trace("newBF");
		switch (SONG.player1) // no clue why i didnt think of this before lol
		{
			default:
				//boyfriend.x += boyfriend.bfOffsetX; //just use sprite offsets
				//boyfriend.y += boyfriend.bfOffsetY;
				camPos.x += boyfriend.camOffsetX;
				camPos.y += boyfriend.camOffsetY;
				if (boyfriend.like == "gf") {
					boyfriend.setPosition(gf.x, gf.y);
					gf.visible = false;
					if (isStoryMode)
					{
						camPos.x += 600;
						tweenCamIn();
					}
				}
		}

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'schoolEvil':
				// trailArea.scrollFactor.set();
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			default:
				boyfriend.x += bfoffset[0];
				boyfriend.y += bfoffset[1];
				gf.x += gfoffset[0];
				gf.y += gfoffset[1];
				dad.x += dadoffset[0];
				dad.y += dadoffset[1];

		}
		trace('befpre spoop check');
		if (SONG.isSpooky) {
			trace("WOAH SPOOPY");
			var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
			// evilTrail.changeValuesEnabled(false, false, false, false);
			// evilTrail.changeGraphic()
			add(evilTrail);
		}
		trace('big titted goth gf');
		add(gf);
		trace('anime thighs she only 5');
		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);
		add(foregroundgroup);
		trace('dad');
		add(dad);
		trace('dy UWU');
		add(boyfriend);
		trace('bf cheeks');

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		trace('doofensmiz');
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		Conductor.songPosition = -5000;
		trace('prepare your strumlime');
		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		enemyStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();
		trace('before generate');
		generateSong(SONG.song);

		// add(strumLine);
		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		trace('gay');
		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic('assets/images/healthBar.png');
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 90, healthBarBG.y + 30, 0, "", 200);
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		scoreTxt.scrollFactor.set();

		healthTxt = new FlxText(healthBarBG.x + healthBarBG.width - 300, healthBarBG.y + 30, 0, "", 200);
		healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		healthTxt.scrollFactor.set();

		accuracyTxt = new FlxText(healthBarBG.x, healthBarBG.y + 30, 0, "", 200);
		accuracyTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		accuracyTxt.scrollFactor.set();
		difficTxt = new FlxText(10, FlxG.height, 0, "", 200);

		difficTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		difficTxt.scrollFactor.set();
		difficTxt.y -= difficTxt.height;
		// screwy way of getting text
		difficTxt.text = DifficultyIcons.changeDifficultyFreeplay(storyDifficulty, 0).text;
		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);
		practiceDieIcon = new HealthIcon('bf-old', false);
		practiceDieIcon.y = healthBar.y - (practiceDieIcon.height / 2);
		practiceDieIcon.x = healthBar.x - 130;
		practiceDieIcon.animation.curAnim.curFrame = 1;
		add(practiceDieIcon);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		practiceDieIcon.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		healthTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		accuracyTxt.cameras = [camHUD];
		difficTxt.cameras = [camHUD];
		practiceDieIcon.visible = false;

		add(scoreTxt);
		add(healthTxt);

		add(accuracyTxt);
		add(difficTxt);
		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		trace('finish uo');
	if (alwaysDoCutscenes || isStoryMode )
		{

			switch (SONG.cutsceneType)
			{
				case "monster":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play('assets/sounds/Lights_Turn_On' + TitleState.soundExt);
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'angry-senpai':
					FlxG.sound.play('assets/sounds/ANGRY' + TitleState.soundExt);
					schoolIntro(doof);
				case 'spirit':
					schoolIntro(doof);
				case 'none':
					startCountdown();
				default:
					schoolIntro(doof);
			}
		}
		else
		{

			startCountdown();
		}

		super.create();

	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		var senpaiSound:Sound;
		// try and find a player2 sound first
		if (FileSystem.exists('assets/images/custom_chars/'+SONG.player2+'/Senpai_Dies.ogg')) {
			senpaiSound = Sound.fromFile('assets/images/custom_chars/'+SONG.player2+'/Senpai_Dies.ogg');
		// otherwise, try and find a song one
		} else if (FileSystem.exists('assets/data/'+SONG.song.toLowerCase()+'/Senpai_Dies.ogg')) {
			senpaiSound = Sound.fromFile('assets/data/'+SONG.song.toLowerCase()+'Senpai_Dies.ogg');
		// otherwise, use the default sound
		} else {
			senpaiSound = Sound.fromFile('assets/sounds/Senpai_Dies.ogg');
		}
		var senpaiEvil:FlxSprite = new FlxSprite();
		// dialog box overwrites character
		if (FileSystem.exists('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'/crazy.png')) {
			var evilImage = BitmapData.fromFile('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'/crazy.png');
			var evilXml = File.getContent('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'/crazy.xml');
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow(evilImage, evilXml);
		// character then takes precendence over default
		// will make things like monika way way easier
		} else if (FileSystem.exists('assets/images/custom_chars/'+SONG.player2+'/crazy.png')) {
			var evilImage = BitmapData.fromFile('assets/images/custom_chars/'+SONG.player2+'/crazy.png');
			var evilXml = File.getContent('assets/images/custom_chars/'+SONG.player2+'/crazy.xml');
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow(evilImage, evilXml);
		} else {
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/senpaiCrazy.png', 'assets/images/weeb/senpaiCrazy.xml');
		}

		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		if (dad.isPixel) {
			senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		}
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (dialogueBox != null && dialogueBox.like != 'senpai')
		{
			remove(black);

			if (dialogueBox.like == 'spirit')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (dialogueBox.like == 'spirit')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(senpaiSound, 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectModeOld:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);
		#if windows
		if (FileSystem.exists("assets/images/custom_stages/" + SONG.stage + "/process.lua")) // dude I hate lua (jkjkjkjk)
		{
			makeLuaState("stages", "assets/images/custom_stages/"+SONG.stage+"/", "process.lua");
		}
		if (FileSystem.exists("assets/data/" + SONG.song.toLowerCase() + "/modchart.lua")) // dude I hate lua (jkjkjkjk)
		{
			makeLuaState("modchart", "assets/data/" + SONG.song.toLowerCase() + "/", "/modchart.lua");
		}
		#end
		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();


			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('normal', ['ready.png', "set.png", "go.png"]);
			introAssets.set('pixel', [
				'weeb/pixelUI/ready-pixel.png',
				'weeb/pixelUI/set-pixel.png',
				'weeb/pixelUI/date-pixel.png'
			]);
			for (field in CoolUtil.coolTextFile('assets/data/uitypes.txt')) {
				if (field != 'pixel' && field != 'normal') {
					if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						introAssets.set(field, ['custom_ui/ui_packs/'+field+'/ready-pixel.png','custom_ui/ui_packs/'+field+'/set-pixel.png','custom_ui/ui_packs/'+field+'/date-pixel.png']);
					else
						introAssets.set(field, ['custom_ui/ui_packs/'+field+'/ready.png','custom_ui/ui_packs/'+field+'/set.png','custom_ui/ui_packs/'+field+'/go.png']);
				}
			}

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";
			var intro3Sound:Sound;
			var intro2Sound:Sound;
			var intro1Sound:Sound;
			var introGoSound:Sound;
			for (value in introAssets.keys())
			{
				if (value == SONG.uiType)
				{
					introAlts = introAssets.get(value);
					// ok so apparently a leading slash means absolute soooooo
					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						altSuffix = '-pixel';
				}
			}
			if (SONG.uiType == 'normal') {
				intro3Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro3.ogg')));
				intro2Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro2.ogg')));
				intro1Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro1.ogg')));
				introGoSound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/introGo.ogg')));
			} else if (SONG.uiType == 'pixel') {
				intro3Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro3-pixel.ogg')));
				intro2Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro2-pixel.ogg')));
				intro1Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro1-pixel.ogg')));
				introGoSound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/introGo-pixel.ogg')));
			} else {
				// god is dead for we have killed him
				intro3Sound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro3'+altSuffix+'.ogg');
				intro2Sound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro2'+altSuffix+'.ogg');
				intro1Sound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro1'+altSuffix+'.ogg');
				// apparently this crashes if we do it from audio buffer?
				// no it just understands 'hey that file doesn't exist better do an error'
				introGoSound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/introGo'+altSuffix+'.ogg');
			}


			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(intro3Sound, 0.6);
				case 1:
					// my life is a lie, it was always this simple
					var readyImage = BitmapData.fromFile('assets/images/'+introAlts[0]);
					var ready:FlxSprite = new FlxSprite().loadGraphic(readyImage);
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(intro2Sound, 0.6);
				case 2:
					var setImage = BitmapData.fromFile('assets/images/'+introAlts[1]);
					// can't believe you can actually use this as a variable name
					var set:FlxSprite = new FlxSprite().loadGraphic(setImage);
					set.scrollFactor.set();

					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(intro1Sound, 0.6);
				case 3:
					var goImage = BitmapData.fromFile('assets/images/'+introAlts[2]);
					var go:FlxSprite = new FlxSprite().loadGraphic(goImage);
					go.scrollFactor.set();

					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(introGoSound, 0.6);
				case 4:
					// what is this here for?
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
		regenTimer = new FlxTimer().start(2, function (tmr:FlxTimer) {
			if (poisonExr && !paused)
				health -= 0.005;
			if (supLove && !paused)
				health +=  0.005;
		}, 0);
		sickFastTimer = new FlxTimer().start(2, function (tmr:FlxTimer) {
			if (accelNotes && !paused) {
				trace("tick:" + noteSpeed);
				noteSpeed += 0.01;
			}

		}, 0);
		var snekBase:Float = 0;
		var snekTimer = new FlxTimer().start(0.01, function (tmr:FlxTimer) {
			if (snakeNotes && !paused) {
				snekNumber = Math.sin(snekBase) * 100;
				snekBase += Math.PI/100;
			}

		}, 0);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;
		if (FlxG.sound.music != null) {
			// cuck lunchbox
			FlxG.sound.music.stop();
		}
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			#if sys
			FlxG.sound.playMusic(Sound.fromFile("assets/music/"+SONG.song+"_Inst"+TitleState.soundExt), 1, false);
			#else
			FlxG.sound.playMusic("assets/music/" + SONG.song + "_Inst" + TitleState.soundExt, 1, false);
			#end
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices) {
			#if sys
			var vocalSound = Sound.fromFile("assets/music/"+SONG.song+"_Voices"+TitleState.soundExt);
			vocals = new FlxSound().loadEmbedded(vocalSound);
			#else
			vocals = new FlxSound().loadEmbedded("assets/music/" + curSong + "_Voices" + TitleState.soundExt);
			#end
		}	else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		var customImage:Null<BitmapData> = null;
		var customXml:Null<String> = null;
		var arrowEndsImage:Null<BitmapData> = null;
		if (SONG.uiType != 'normal' && SONG.uiType != 'pixel') {
			if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml") && FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png")) {
				trace("has this been reached");
				customImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/NOTE_assets.png');
				customXml = File.getContent('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/NOTE_assets.xml');
			} else {
				customImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/arrow-pixels.png');
				arrowEndsImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/arrowEnds.png');
			}
		}

		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, customImage, customXml, arrowEndsImage);
				// so much more complicated but makes playstation like shit work
				if (flippedNotes) {
					if (swagNote.animation.curAnim.name == 'greenScroll') {
						swagNote.animation.play('blueScroll');
					} else if (swagNote.animation.curAnim.name == 'blueScroll') {
						swagNote.animation.play('greenScroll');
					} else if (swagNote.animation.curAnim.name == 'redScroll') {
						swagNote.animation.play('purpleScroll');
					} else if (swagNote.animation.curAnim.name == 'purpleScroll') {
						swagNote.animation.play('redScroll');
					}
				}
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				// when the imposter is sus XD
				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, customImage, customXml, arrowEndsImage);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}


				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else
				{
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;
		// to get around how pecked up the note system is
		for (epicNote in unspawnNotes) {
			if (epicNote.isSustainNote) {
				if (flippedNotes) {
					if (epicNote.animation.curAnim.name == 'greenhold') {
						epicNote.animation.play('bluehold');
					} else if (epicNote.animation.curAnim.name == 'bluehold') {
						epicNote.animation.play('greenhold');
					} else if (epicNote.animation.curAnim.name == 'redhold') {
						epicNote.animation.play('purplehold');
					} else if (epicNote.animation.curAnim.name == 'purplehold') {
						epicNote.animation.play('redhold');
					} else if (epicNote.animation.curAnim.name == 'greenholdend') {
						epicNote.animation.play('blueholdend');
					} else if (epicNote.animation.curAnim.name == 'blueholdend') {
						epicNote.animation.play('greenholdend');
					} else if (epicNote.animation.curAnim.name == 'redholdend') {
						epicNote.animation.play('purpleholdend');
					} else if (epicNote.animation.curAnim.name == 'purpleholdend') {
						epicNote.animation.play('redholdend');
					}
				}
			}
		}
		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			switch (SONG.uiType)
			{
				case 'pixel':
					babyArrow.loadGraphic('assets/images/weeb/pixelUI/arrows-pixels.png', true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);
					if (flippedNotes) {
						babyArrow.animation.add('blue', [6]);
						babyArrow.animation.add('purplel', [7]);
						babyArrow.animation.add('green', [5]);
						babyArrow.animation.add('red', [4]);
					}
					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [1]);
								babyArrow.animation.add('pressed', [5, 9], 12, false);
								babyArrow.animation.add('confirm', [13, 17], 12, false);
							}
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [0]);
								babyArrow.animation.add('pressed', [4, 8], 12, false);
								babyArrow.animation.add('confirm', [12, 16], 24, false);
							}
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [2]);
								babyArrow.animation.add('pressed', [6, 10], 12, false);
								babyArrow.animation.add('confirm', [14, 18], 12, false);
							}
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [3]);
								babyArrow.animation.add('pressed', [7, 11], 12, false);
								babyArrow.animation.add('confirm', [15, 19], 24, false);
							}
					}

				case 'normal':
					babyArrow.frames = FlxAtlasFrames.fromSparrow('assets/images/NOTE_assets.png', 'assets/images/NOTE_assets.xml');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
					if (flippedNotes) {
						babyArrow.animation.addByPrefix('blue', 'arrowUP');
						babyArrow.animation.addByPrefix('green', 'arrowDOWN');
						babyArrow.animation.addByPrefix('red', 'arrowLEFT');
						babyArrow.animation.addByPrefix('purple', 'arrowRIGHT');
					}
					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowDOWN');
								babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
							}
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowLEFT');
								babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
							}
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowUP');
								babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
							}
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
								babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
				default:
					if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml") && FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png")) {

					  var noteXml = File.getContent('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml");
						var notePic = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png");
						babyArrow.frames = FlxAtlasFrames.fromSparrow(notePic, noteXml);
						babyArrow.animation.addByPrefix('green', 'arrowUP');
						babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
						babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
						babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
						if (flippedNotes) {
							babyArrow.animation.addByPrefix('blue', 'arrowUP');
							babyArrow.animation.addByPrefix('green', 'arrowDOWN');
							babyArrow.animation.addByPrefix('red', 'arrowLEFT');
							babyArrow.animation.addByPrefix('purple', 'arrowRIGHT');
						}
						babyArrow.antialiasing = true;
						babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

						switch (Math.abs(i))
						{
							case 2:
								babyArrow.x += Note.swagWidth * 2;
								babyArrow.animation.addByPrefix('static', 'arrowUP');
								babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								}
							case 3:
								babyArrow.x += Note.swagWidth * 3;
								babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
								babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								}
							case 1:
								babyArrow.x += Note.swagWidth * 1;
								babyArrow.animation.addByPrefix('static', 'arrowDOWN');
								babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								}
							case 0:
								babyArrow.x += Note.swagWidth * 0;
								babyArrow.animation.addByPrefix('static', 'arrowLEFT');
								babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								}
						}

					} else if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png")){
						var notePic = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png");
						babyArrow.loadGraphic(notePic, true, 17, 17);
						babyArrow.animation.add('green', [6]);
						babyArrow.animation.add('red', [7]);
						babyArrow.animation.add('blue', [5]);
						babyArrow.animation.add('purplel', [4]);
						if (flippedNotes) {
							babyArrow.animation.add('blue', [6]);
							babyArrow.animation.add('purplel', [7]);
							babyArrow.animation.add('green', [5]);
							babyArrow.animation.add('red', [4]);
						}
						babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
						babyArrow.updateHitbox();
						babyArrow.antialiasing = false;

						switch (Math.abs(i))
						{
							case 2:
								babyArrow.x += Note.swagWidth * 2;
								babyArrow.animation.add('static', [2]);
								babyArrow.animation.add('pressed', [6, 10], 12, false);
								babyArrow.animation.add('confirm', [14, 18], 12, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [1]);
									babyArrow.animation.add('pressed', [5, 9], 12, false);
									babyArrow.animation.add('confirm', [13, 17], 12, false);
								}
							case 3:
								babyArrow.x += Note.swagWidth * 3;
								babyArrow.animation.add('static', [3]);
								babyArrow.animation.add('pressed', [7, 11], 12, false);
								babyArrow.animation.add('confirm', [15, 19], 24, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [0]);
									babyArrow.animation.add('pressed', [4, 8], 12, false);
									babyArrow.animation.add('confirm', [12, 16], 24, false);
								}
							case 1:
								babyArrow.x += Note.swagWidth * 1;
								babyArrow.animation.add('static', [1]);
								babyArrow.animation.add('pressed', [5, 9], 12, false);
								babyArrow.animation.add('confirm', [13, 17], 24, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [2]);
									babyArrow.animation.add('pressed', [6, 10], 12, false);
									babyArrow.animation.add('confirm', [14, 18], 12, false);
								}
							case 0:
								babyArrow.x += Note.swagWidth * 0;
								babyArrow.animation.add('static', [0]);
								babyArrow.animation.add('pressed', [4, 8], 12, false);
								babyArrow.animation.add('confirm', [12, 16], 24, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [3]);
									babyArrow.animation.add('pressed', [7, 11], 12, false);
									babyArrow.animation.add('confirm', [15, 19], 24, false);
								}
						}
					} else {
						// no crashing today :)
						babyArrow.frames = FlxAtlasFrames.fromSparrow('assets/images/NOTE_assets.png', 'assets/images/NOTE_assets.xml');
						babyArrow.animation.addByPrefix('green', 'arrowUP');
						babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
						babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
						babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
						if (flippedNotes) {
							babyArrow.animation.addByPrefix('blue', 'arrowUP');
							babyArrow.animation.addByPrefix('green', 'arrowDOWN');
							babyArrow.animation.addByPrefix('red', 'arrowLEFT');
							babyArrow.animation.addByPrefix('purple', 'arrowRIGHT');
						}
						babyArrow.antialiasing = true;
						babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

						switch (Math.abs(i))
						{
							case 2:
								babyArrow.x += Note.swagWidth * 2;
								babyArrow.animation.addByPrefix('static', 'arrowUP');
								babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								}
							case 3:
								babyArrow.x += Note.swagWidth * 3;
								babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
								babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								}
							case 1:
								babyArrow.x += Note.swagWidth * 1;
								babyArrow.animation.addByPrefix('static', 'arrowDOWN');
								babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								}
							case 0:
								babyArrow.x += Note.swagWidth * 0;
								babyArrow.animation.addByPrefix('static', 'arrowLEFT');
								babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								}
						}
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			} else {
				enemyStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectModeOld = false;
		#end
		#if windows
		setAllVar('songPos', Conductor.songPosition);
		setAllVar('hudZoom', camHUD.zoom);
		setAllVar('cameraZoom', FlxG.camera.zoom);
		callAllLua('update', [elapsed], null);
		if (luaStates.exists("modchart")) {
			FlxG.camera.angle = getVar('cameraAngle', 'float', 'modchart');
			camHUD.angle = getVar('camHudAngle', 'float', 'modchart');

			if (getVar("showOnlyStrums", 'bool', 'modchart'))
			{
				healthBarBG.visible = false;
				healthBar.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
				scoreTxt.visible = false;
			}
			else
			{
				healthBarBG.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
				scoreTxt.visible = true;
			}

			var p1 = getVar("strumLine1Visible", 'bool', 'modchart');
			var p2 = getVar("strumLine2Visible", 'bool', 'modchart');

			for (i in 0...4)
			{
				strumLineNotes.members[i].visible = p1;
				if (i <= playerStrums.length)
					playerStrums.members[i].visible = p2;
			}
		}
		
		#end
		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		super.update(elapsed);
		healthTxt.text = "Health:" + Math.round(health * 50) + "%";
		scoreTxt.text = "Score:" + songScore + "(" + trueScore + ")";
		if (notesPassing != 0) {
			accuracyTxt.text = "Accuracy:" + Math.round((notesHit/notesPassing) * 100) + "%";
		} else {
			accuracyTxt.text = "Accuracy:100%";
		}
		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));
		practiceDieIcon.setGraphicSize(Std.int(FlxMath.lerp(150, practiceDieIcon.width, 0.50)));
		iconP1.updateHitbox();
		iconP2.updateHitbox();
		practiceDieIcon.updateHitbox();
		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;
		if (poisonTimes == 0) {
			if (healthBar.percent < 20) {
				iconP1.animation.curAnim.curFrame = 1;
				healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.RED, RIGHT);
			}
			else {
				iconP1.animation.curAnim.curFrame = 0;
				healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
			}

		} else {
			iconP1.animation.curAnim.curFrame = 2;
		}


		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		if (FlxG.keys.justPressed.EIGHT) // stop checking for debug so i can fix my offsets!
			FlxG.switchState(new AnimationDebug(SONG.player2, SONG.player1));

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (curBeat % 4 == 0)
			{
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}
			#if windows
			
			setAllVar("mustHit", PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			#end
			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
				#if windows
				callAllLua("playerTwoTurn", [], null);
				#end
				if (dad.like == 'mom')
					camFollow.y = dad.getMidpoint().y;
				if (dad.like == 'senpai' || dad.like == 'senpai-angry') {
					camFollow.y = dad.getMidpoint().y - 430;
					camFollow.x = dad.getMidpoint().x - 100;
				}
				if (dad.isCustom) {
					camFollow.y = dad.getMidpoint().y + dad.followCamY;
					camFollow.x = dad.getMidpoint().x + dad.followCamX;
				}
				vocals.volume = 1;
				/*
				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
				*/
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition((boyfriend.getMidpoint().x - 100 + boyfriend.followCamX), (boyfriend.getMidpoint().y - 100+boyfriend.followCamY));
				#if windows
				callAllLua("playerOneTurn", [], null);
				#end
				switch (curStage)
				{
					// not sure that's how variable assignment works
					#if !windows
					case 'limo':
						camFollow.x = boyfriend.getMidpoint().x - 300 + boyfriend.followCamX; // why are you hard coded
					
					case 'mall':
						camFollow.y = boyfriend.getMidpoint().y - 200 + boyfriend.followCamY;
					#end
					case 'school':
						camFollow.x = boyfriend.getMidpoint().x - 200 + boyfriend.followCamX;
						camFollow.y = boyfriend.getMidpoint().y - 200 + boyfriend.followCamY;
					case 'schoolEvil':
						camFollow.x = boyfriend.getMidpoint().x - 200 + boyfriend.followCamX;
						camFollow.y = boyfriend.getMidpoint().y - 200 + boyfriend.followCamY;
				}
				
				/*
				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
				*/
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET)
		{
			health = 0;
			trace("RESET = True");
		}

		// CHEAT = brandon's a pussy
		if (controls.CHEAT)
		{
			health += 1;
			trace("User is cheating!");
		}

		if (health <= 0 && !practiceMode)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();
			if (inALoop) {
				FlxG.switchState(new PlayState());
			} else {
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				// 1 / 1000 chance for Gitaroo Man easter egg
				if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					FlxG.switchState(new GitarooPause());
				}
				else
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			}

			
			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		} else if (health <= 0 && !practiceDied) {
			practiceDied = true;
			practiceDieIcon.visible = true;
		}
		health = FlxMath.bound(health,0,2);
		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = !invsNotes;
					daNote.active = true;
				}
				if (!daNote.modifiedByLua) {
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					// i am so fucking sorry for this if condition
					if (daNote.isSustainNote
						&& daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
						swagRect.y /= daNote.scale.y;
						swagRect.height -= swagRect.y;

						daNote.clipRect = swagRect;
					}
				}
				

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					/*
					if (SONG.song != 'Tutorial')
						camZooming = true;
					*/
					var altAnim:String = "";
					
					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if ((SONG.notes[Math.floor(curStep / 16)].altAnimNum > 0 && SONG.notes[Math.floor(curStep / 16)].altAnimNum != null) || SONG.notes[Math.floor(curStep / 16)].altAnim)
							// backwards compatibility shit
							if (SONG.notes[Math.floor(curStep / 16)].altAnimNum == 1 || SONG.notes[Math.floor(curStep / 16)].altAnim)
								altAnim = '-alt';
							else if (SONG.notes[Math.floor(curStep / 16)].altAnimNum != 0)
								altAnim = '-' + SONG.notes[Math.floor(curStep / 16)].altAnimNum+'alt';
					}
					#if windows
					callAllLua("playerTwoSing", [], null);
					#end
					switch (Math.abs(daNote.noteData))
					{
						case 0:
							
							dad.playAnim('singLEFT' + altAnim, true);
						case 1:
							dad.playAnim('singDOWN' + altAnim, true);
						case 2:
							dad.playAnim('singUP' + altAnim, true);
						case 3:
							dad.playAnim('singRIGHT' + altAnim, true);
					}
					enemyStrums.forEach(function(spr:FlxSprite)
					{
						if (Math.abs(daNote.noteData) == spr.ID)
						{
							spr.animation.play('confirm');
							sustain2(spr.ID, spr, daNote);
						}
					});
					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}



				if (drunkNotes) {
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * ((Math.sin(songTime/400)/6)+0.5) * noteSpeed * FlxMath.roundDecimal(PlayState.SONG.speed, 2));
				} else {
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (noteSpeed * FlxMath.roundDecimal(PlayState.SONG.speed, 2)));
				}
				if (vnshNotes)
					daNote.alpha = FlxMath.remapToRange(daNote.y, strumLine.y, FlxG.height, 0, 1);
				if (snakeNotes) {
					if (daNote.mustPress) {
						daNote.x = (FlxG.width/2)+snekNumber+(Note.swagWidth*daNote.noteData)+50;
					} else {
						daNote.x = snekNumber+(Note.swagWidth*daNote.noteData)+50;
					}
				}
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if (daNote.y < -daNote.height)
				{

						if ((daNote.tooLate || !daNote.wasGoodHit) && !daNote.isSustainNote)
						{
							health -= 0.0475;
							vocals.volume = 0;
							if (poisonPlus && poisonTimes < 3)
							{
								poisonTimes += 1;
								var poisonPlusTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
								{
									health -= 0.04;
								}, 0);
								// stop timer after 3 seconds
								new FlxTimer().start(3, function(tmr:FlxTimer)
								{
									poisonPlusTimer.cancel();
									poisonTimes -= 1;
								});
							}
							if (fullComboMode || perfectMode)
							{
								// you signed up for this your fault
								health = 0;
							}
						}

						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
				}
				enemyStrums.forEach(function(spr:FlxSprite)
				{
					if (strumming2[spr.ID])
					{
						spr.animation.play("confirm");
					}

					if (spr.animation.curAnim.name == 'confirm' && !daNote.isPixel)
					{
						spr.centerOffsets();
						spr.offset.x -= 13;
						spr.offset.y -= 13;
					}
					else
						spr.centerOffsets();
				});
			});
		}

		if (!inCutscene)
			keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}
	function sustain2(strum:Int, spr:FlxSprite, note:Note):Void
	{
		var length:Float = note.sustainLength;

		if (length > 0)
		{
			strumming2[strum] = true;
		}

		var bps:Float = Conductor.bpm / 60;
		var spb:Float = 1 / bps;

		if (!note.isSustainNote)
		{
			new FlxTimer().start(length == 0 ? 0.2 : (length / Conductor.crochet * spb) + 0.1, function(tmr:FlxTimer)
			{
				if (!strumming2[strum])
				{
					spr.animation.play("static", true);
				}
				else if (length > 0)
				{
					strumming2[strum] = false;
					spr.animation.play("static", true);
				}
			});
		}
	}
	function endSong():Void
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		
		#if !switch
		Highscore.saveScore(SONG.song, songScore, storyDifficulty, (notesHit / notesPassing));
		#end

		if (isStoryMode)
		{
			campaignScore += songScore;
			campaignAccuracy += notesHit/notesPassing;
			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);

				

				Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty, campaignAccuracy / defaultPlaylistLength);

				campaignAccuracy = campaignAccuracy / defaultPlaylistLength;
				if (useVictoryScreen) {
					FlxG.switchState(new VictoryLoopState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, gf.getScreenPosition().x, gf.getScreenPosition().y, campaignAccuracy, campaignScore));
				} else {
					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;
					FlxG.switchState(new StoryMenuState());
				}
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				difficulty = DifficultyIcons.getEndingFP(storyDifficulty);
				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play('assets/sounds/Lights_Shut_off' + TitleState.soundExt);
				}

				if (SONG.song.toLowerCase() == 'senpai')
				{
					FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;
				}
				if (FileSystem.exists('assets/data/'+PlayState.storyPlaylist[0].toLowerCase()+'/'+PlayState.storyPlaylist[0].toLowerCase()+difficulty+'.json'))
				  // do this to make custom difficulties not as unstable
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				else
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase(), PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				FlxG.switchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			if (useVictoryScreen) {
				FlxG.switchState(new VictoryLoopState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, gf.getScreenPosition().x,gf.getScreenPosition().y, notesHit/notesPassing, songScore));
			} else
				FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			notesHit += 0.25;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
			notesHit += 0.75;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
			// good needs to be punished somewhat
			notesHit += 0.95;
		}
		if (daRating == 'sick')
			notesHit += 1;
		if (daRating != "sick" && perfectMode) {
			health = -50;
		}
		if (notesHit > notesPassing) {
			notesHit = notesPassing;
		}
		songScore += Math.round(score * ModifierState.scoreMultiplier);
		trueScore += score;
		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';
		if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png")) {
			pixelShitPart2 = '-pixel';
		}
		var ratingImage:BitmapData;
		switch (SONG.uiType) {
			case 'pixel':
				ratingImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/weeb/pixelUI/'+daRating+'-pixel.png')));
			case 'normal':
				ratingImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/'+daRating+'.png')));
			default:
				ratingImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+PlayState.SONG.uiType+'/'+daRating+pixelShitPart2+".png");
		}

		rating.loadGraphic(ratingImage);
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(ratingImage);
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);
		// gonna be fun explaining this
		if (SONG.uiType != 'pixel' && !FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numImage:BitmapData;
			switch (SONG.uiType) {
				case 'pixel':
					numImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/weeb/pixelUI/num'+Std.int(i)+'-pixel.png')));
				case 'normal':
					numImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/num'+Std.int(i)+'.png')));
				default:
					numImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/num'+Std.int(i)+pixelShitPart2+".png");
			}
			var numScore:FlxSprite = new FlxSprite().loadGraphic(numImage);
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (SONG.uiType != 'pixel' && !FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.UP;
		var right = controls.RIGHT;
		var down = controls.DOWN;
		var left = controls.LEFT;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var upR = controls.UP_R;
		var rightR = controls.RIGHT_R;
		var downR = controls.DOWN_R;
		var leftR = controls.LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

		// FlxG.watch.addQuick('asdfa', upP);
		if ((upP || rightP || downP || leftP) && !boyfriend.stunned && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];

			var ignoreList:Array<Int> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
				{
					// the sorting probably doesn't need to be in here? who cares lol
					possibleNotes.push(daNote);
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					ignoreList.push(daNote.noteData);
				}
			});

			if (possibleNotes.length > 0)
			{
				var daNote = possibleNotes[0];

				if (perfectModeOld)
					noteCheck(true, daNote);

				// Jump notes
				if (possibleNotes.length >= 2)
				{
					if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
					{
						for (coolNote in possibleNotes)
						{
							if (controlArray[coolNote.noteData])
								goodNoteHit(coolNote);
							else
							{
								var inIgnoreList:Bool = false;
								for (shit in 0...ignoreList.length)
								{
									if (controlArray[ignoreList[shit]])
										inIgnoreList = true;
								}
								if (!inIgnoreList)
									badNoteCheck();
							}
						}
					}
					else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
					{
						noteCheck(controlArray[daNote.noteData], daNote);
					}
					else
					{
						for (coolNote in possibleNotes)
						{
							noteCheck(controlArray[coolNote.noteData], coolNote);
						}
					}
				}
				else // regular notes?
				{
					noteCheck(controlArray[daNote.noteData], daNote);
				}
				/*
					if (controlArray[daNote.noteData])
						goodNoteHit(daNote);
				 */
				// trace(daNote.noteData);
				/*
					switch (daNote.noteData)
					{
						case 2: // NOTES YOU JUST PRESSED
							if (upP || rightP || downP || leftP)
								noteCheck(upP, daNote);
						case 3:
							if (upP || rightP || downP || leftP)
								noteCheck(rightP, daNote);
						case 1:
							if (upP || rightP || downP || leftP)
								noteCheck(downP, daNote);
						case 0:
							if (upP || rightP || downP || leftP)
								noteCheck(leftP, daNote);
					}
				 */
				if (daNote.wasGoodHit)
				{
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			}
			else
			{
				badNoteCheck();
			}
		}

		if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 0:
							if (left)
								goodNoteHit(daNote);
						case 1:
							if (down)
								goodNoteHit(daNote);
						case 2:
							if (up)
								goodNoteHit(daNote);
						case 3:
							if (right)
								goodNoteHit(daNote);
					}
				}
			});
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left)
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
				trace("idle from non miss sing");
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			switch (spr.ID)
			{
				case 0:
					if (leftP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (leftR)
						spr.animation.play('static');
				case 1:
					if (downP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (downR)
						spr.animation.play('static');
				case 2:
					if (upP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (upR)
						spr.animation.play('static');
				case 3:
					if (rightP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (rightR)
						spr.animation.play('static');
			}
			
			if (spr.animation.curAnim.name == 'confirm' && SONG.uiType != 'pixel' && !FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1):Void
	{
		if (fullComboMode || perfectMode) {
			// you signed up for this your fault
			health = 0;
		}
		if (!boyfriend.stunned)
		{
			notesPassing += 1;
			health -= 0.04 + healthLossModifier;
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			combo = 0;
			if (!practiceMode) {
				songScore -= 10;

			}
			trueScore -= 10;
			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play('assets/sounds/missnote1' + TitleState.soundExt, 1, false);
			// FlxG.log.add('played imss note');

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (direction)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}
			#if windows
			callAllLua("playerOneMiss", [], null);
			#end
		}
	}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		if (leftP)
			noteMiss(0);
		if (downP)
			noteMiss(1);
		if (upP)
			noteMiss(2);
		if (rightP)
			noteMiss(3);
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
		else
		{
			badNoteCheck();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				notesPassing += 1;
				popUpScore(note.strumTime);
				combo += 1;
			}

			if (note.noteData >= 0)
				health += 0.023 + healthGainModifier;
			else
				health += 0.004 + healthGainModifier;

			switch (note.noteData)
			{
				case 0:
					boyfriend.playAnim('singLEFT', true);
				case 1:
					boyfriend.playAnim('singDOWN', true);
				case 2:
					boyfriend.playAnim('singUP', true);
				case 3:
					boyfriend.playAnim('singRIGHT', true);
			}
			#if windows
			callAllLua("playerOneSing", [], null);
			#end
			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play('assets/sounds/carPass' + FlxG.random.int(0, 1) + TitleState.soundExt, 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play('assets/sounds/thunder_' + FlxG.random.int(1, 2) + TitleState.soundExt);
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();
		if (SONG.needsVoices)
		{
			if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
		}
		#if windows
		setAllVar("curStep", curStep);
		callAllLua("stepHit", [curStep], null);
		#end

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
		{
			// dad.dance();
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();
		
		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));
		practiceDieIcon.setGraphicSize(Std.int(practiceDieIcon.width + 30));
		iconP1.updateHitbox();
		iconP2.updateHitbox();
		practiceDieIcon.updateHitbox();
		if (curBeat % gfSpeed == 0)
		{
			gf.dance();
		}

		if (!boyfriend.animation.curAnim.name.startsWith("sing"))
		{
			boyfriend.playAnim('idle');
		}

		if (curBeat % 8 == 7 && SONG.isHey)
		{
			boyfriend.playAnim('hey', true);

			if (SONG.song == 'Tutorial' && dad.like == 'gf')
			{
				dad.playAnim('cheer', true);
			}
		}
		trace(curBeat);
		for (sprite in backgroundgroup.members) {
			sprite.runEvent(curBeat, boyfriend, gf, dad);
		}
		for (sprite in foregroundgroup.members)
		{
			sprite.runEvent(curBeat, boyfriend, gf, dad);
		}
		switch (curStage)
		{
			case 'school':
				bgGirls.dance();
			#if !windows
			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			#end
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		#if windows
		setAllVar('curBeat', curBeat);
		callAllLua('beatHit', [curBeat],null);
		#end
	}

	var curLight:Int = 0;
}
