package;

import flixel.FlxCamera;
import Song.SwagSong;
import flixel.FlxBasic;
import lime.utils.Assets;

#if !js
import Sys;
import sys.FileSystem;
#end

class Modchart extends FlxBasic implements polymod.hscript.HScriptable {
    public var SONG:SwagSong;
    public var bf:Boyfriend;
    public var dad:Character;
    public var gf:Character;
    public var camHUD:FlxCamera;
    public var camGame:FlxCamera;

    public function new(SONG:SwagSong, bf:Boyfriend, dad:Character, gf:Character, camHUD:FlxCamera, camGame:FlxCamera) {
        super();
        start();

        this.SONG = SONG;
        this.bf = bf;
        this.dad = dad;
        this.gf = gf;
        this.camHUD = camHUD;
        this.camGame = camGame;
    }

    @:hscript(SONG, bf, dad, gf, camHUD, camGame)
    function start() {

    }

    @:hscript(SONG, bf, dad, gf, camHUD, camGame)
    public override function update(elapsed:Float) {
        super.update(elapsed);
    }

    @:hscript(SONG, bf, dad, gf, camHUD, camGame)
    public function beatHit(beat:Int) {

    }

    @:hscript(SONG, bf, dad, gf, camHUD, camGame)
    public function stepHit(step:Int) {

    }
}