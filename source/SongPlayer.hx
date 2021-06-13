package;

import flixel.group.FlxGroup;
import Song.SwagSong;

// base class execute song data
class SongPlayer {
	public var bf:Boyfriend;
	public var gf:Character;
	public var dad:Character;

	var playState:FlxGroup;
    var SONG:SwagSong;

	public function new(group:FlxGroup) {
		playState = group;
	}

	public function createDialogue():Void {
		var path = SONG.song.toLowerCase() + '/' + SONG.song.toLowerCase() + '-dialogue';
		// dialogue = CoolUtil.coolTextFile(Paths.txt(path));
		trace("Create dialogue at path: " + path);
	}

	public function showDialogue():Void 
    {

    }

	public function loadSong(song:SwagSong):Void {
        this.SONG = song;
		loadMap();
		createCharacter(song);
	}

	function loadMap():Void {}

	function createCharacter(SONG:SwagSong):Void {
		bf = new Boyfriend(770, 450, SONG.player1);
		gf = new Character(400, 130, SONG.gfVersion);
		dad = new Character(100, 100, SONG.player2);

		playState.add(bf);
		playState.add(gf);
		playState.add(dad);
	}

	public function midSongEventUpdate():Void {}

	public function dadEventUpdate():Void {}

	public function bfEventUpdate():Void {}

	public function gfEventUpdate():Void {}
}