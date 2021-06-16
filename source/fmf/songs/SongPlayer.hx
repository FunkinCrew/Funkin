package fmf.songs;

import fmf.characters.*;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import Song.SwagSong;

// base class execute song data
class SongPlayer
{
	public var bf:Boyfriend;
	public var gf:Character;
	public var dad:Character;

	public var playState:PlayState;
	public var SONG:SwagSong;
	public var dialogue:Array<String>;
	public var dialogueBox:DialogueBox;

	public function new(state:PlayState)
	{
		playState = state;
	}

	public function createDialogue():Void
	{
		var path = SONG.song.toLowerCase() + '/' + SONG.song.toLowerCase() + '-dialogue';
		dialogue = CoolUtil.coolTextFile(Paths.txt(path));
		trace("Create dialogue at path: " + path);
	}

	public function showDialogue(callback:Void->Void):Void
	{
		dialogueBox = new DialogueBox(false, dialogue);
		dialogueBox.scrollFactor.set();
		dialogueBox.finishThing = callback;
		dialogueBox.cameras = [playState.camHUD];
		playState.add(dialogueBox);

		trace('whee mai dialgue siht!');
	}

	public function loadSong(song:SwagSong):Void
	{
		this.SONG = song;
		loadMap();
		createCharacters();
	}

	function loadMap():Void
	{
		playState.defaultCamZoom = 0.9;
		// curStage = 'stage';
		var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
		bg.antialiasing = true;
		bg.scrollFactor.set(0.9, 0.9);
		bg.active = false;
		playState.add(bg);

		var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = true;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		playState.add(stageFront);

		var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.antialiasing = true;
		stageCurtains.scrollFactor.set(1.3, 1.3);
		stageCurtains.active = false;

		playState.add(stageCurtains);
	}

	function createCharacters():Void
	{
		createGF();
		createBF();
		createDad();

		gf.scrollFactor.set(0.95, 0.95);
		
		playState.add(gf);
		playState.add(dad);
		playState.add(bf);

	}


	private function getBFTex():Void
	{
		var tex = Paths.getSparrowAtlas('characters/BoyFriend_Assets');
		bf.frames = tex;
		// tex = null;
	}

	private function setBF()
	{

		bf.dance();
		bf.flipX = !bf.flipX;

		// Doesn't flip for BF, since his are already in the right place???		{
		var oldRight = bf.animation.getByName('singRIGHT').frames;
		bf.animation.getByName('singRIGHT').frames = bf.animation.getByName('singLEFT').frames;
		bf.animation.getByName('singLEFT').frames = oldRight;

		// IF THEY HAVE MISS ANIMATIONS??
		if (bf.animation.getByName('singRIGHTmiss') != null)
		{
			var oldMiss = bf.animation.getByName('singRIGHTmiss').frames;
			bf.animation.getByName('singRIGHTmiss').frames = bf.animation.getByName('singLEFTmiss').frames;
			bf.animation.getByName('singLEFTmiss').frames = oldMiss;
		}
		
	}

	private function createBFAnimations():Void
	{
		
		bf.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		bf.animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
		bf.animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
		bf.animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
		bf.animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
		bf.animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
		bf.animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
		bf.animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
		bf.animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
		bf.animation.addByPrefix('hey', 'BF HEY', 24, false);

		bf.animation.addByPrefix('firstDeath', "BF dies", 24, false);
		bf.animation.addByPrefix('deathLoop', "BF Dead Loop", 24, true);
		bf.animation.addByPrefix('deathConfirm', "BF Dead confirm", 24, false);
		bf.animation.addByPrefix('scared', 'BF idle shaking', 24);
	}

	
	private function createBFAnimationOffsets():Void
	{

		bf.addOffset('idle', -5);
		bf.addOffset("singUP", -29, 27);
		bf.addOffset("singRIGHT", -38, -7);
		bf.addOffset("singLEFT", 12, -6);
		bf.addOffset("singDOWN", -10, -50);
		bf.addOffset("singUPmiss", -29, 27);
		bf.addOffset("singRIGHTmiss", -30, 21);
		bf.addOffset("singLEFTmisss", 12, 24);
		bf.addOffset("singDOWNmiss", -11, -19);
		bf.addOffset("hey", 7, 4);
		bf.addOffset('firstDeath', 37, 11);
		bf.addOffset('deathLoop', 37, 5);
		bf.addOffset('deathConfirm', 37, 69);
		bf.addOffset('scared', -4);
	}

	public function createBF():Void
	{
		bf = new Boyfriend(770, 450);
		getBFTex();
		createBFAnimations();
		createBFAnimationOffsets();

		bf.playAnim('idle');
		bf.flipX = true;

		setBF();
	}

	private function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('gf/GF_tutorial');
		gf.frames = tex;
		// tex = null;
	}

	private function createGFAnimations():Void
	{
		var animation = gf.animation;
		animation.addByPrefix('cheer', 'GF Cheer', 24, false);
		animation.addByPrefix('singLEFT', 'GF left note', 24, false);
		animation.addByPrefix('singRIGHT', 'GF Right Note', 24, false);
		animation.addByPrefix('singUP', 'GF Up Note', 24, false);
		animation.addByPrefix('singDOWN', 'GF Down Note', 24, false);
		animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
		animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		animation.addByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
		animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
		animation.addByPrefix('scared', 'GF FEAR', 24);

		gf.animation = animation;

		// animation = null;//alloc
	}

	private function createGFAnimationOffsets():Void
	{
		gf.addOffset('cheer');
		gf.addOffset('sad', -2, -2);
		gf.addOffset('danceLeft', 0, -9);
		gf.addOffset('danceRight', 0, -9);

		gf.addOffset("singUP", 0, 4);
		gf.addOffset("singRIGHT", 0, -20);
		gf.addOffset("singLEFT", 0, -19);
		gf.addOffset("singDOWN", 0, -20);
		gf.addOffset('hairBlow', 45, -8);
		gf.addOffset('hairFall', 0, -9);

		gf.addOffset('scared', -2, -17);
	}

	public function createGF()
	{
		gf = new GF(400, 250);
		getGFTex();
		createGFAnimations();
		createGFAnimationOffsets();
		gf.playAnim('danceRight');

		gf.dance();
	}

	private function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('gf/GF_tutorial');
		dad.frames = tex;
		// tex = null;
	}

	private function createDadAnimations()
	{
		var animation = dad.animation;
		animation.addByPrefix('cheer', 'GF Cheer', 24, false);
		animation.addByPrefix('singLEFT', 'GF left note', 24, false);
		animation.addByPrefix('singRIGHT', 'GF Right Note', 24, false);
		animation.addByPrefix('singUP', 'GF Up Note', 24, false);
		animation.addByPrefix('singDOWN', 'GF Down Note', 24, false);
		animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
		animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		animation.addByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
		animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
		animation.addByPrefix('scared', 'GF FEAR', 24);
		dad.animation = animation;

		// animation = null;//alloc
	}

	private function createDadAnimationOffsets()
	{

		dad.addOffset('cheer');
		dad.addOffset('sad', -2, -2);
		dad.addOffset('danceLeft', 0, -9);
		dad.addOffset('danceRight', 0, -9);

		dad.addOffset("singUP", 0, 4);
		dad.addOffset("singRIGHT", 0, -20);
		dad.addOffset("singLEFT", 0, -19);
		dad.addOffset("singDOWN", 0, -20);
		dad.addOffset('hairBlow', 45, -8);
		dad.addOffset('hairFall', 0, -9);

		dad.addOffset('scared', -2, -17);
	}

	public function createDad()
	{
		dad = new Character(100, 100);
		getDadTex();
		createDadAnimations();
		createDadAnimationOffsets();
		
		dad.playAnim('danceRight');
		dad.dance();
		dad.x = gf.x;
		dad.y = gf.y;
	}

	public function update(elapsed:Float):Void
	{
	}

	public function midSongEventUpdate(curBeat:Int):Void
	{
		
	}

}