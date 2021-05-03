package plugins;

import flixel.group.FlxSpriteGroup;
import PlayState.DisplayLayer;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxCamera;
// A plugin helper
class Stage {
    public var showOnlyStrums:Bool = false;
    public var curStep:Int = 0;
    public var curBeat:Int = 0;
    private var gf:Character;
    private var boyfriend:Character;
    private var dad:Character;
    private var playerStrums:FlxTypedGroup<FlxSprite>;
    private var enemyStrums:FlxTypedGroup<FlxSprite>;
    private var camHUD:FlxCamera;
    public var mustHit:Bool = false;
    public var hscriptPath:String = "";
    public var foregroundGroup:FlxTypedGroup<FlxBasic>;
    public var backgroundGroup:FlxTypedGroup<FlxBasic>;
    public function new (bf:Character, dad:Character, gf:Character, p1Strums:FlxTypedGroup<FlxSprite>, p2Strums:FlxTypedGroup<FlxSprite>, hud:FlxCamera, path:String) {
       
        boyfriend = bf;
        this.dad = dad;
        this.gf = gf;
        playerStrums = p1Strums;
        enemyStrums = p2Strums;
        camHUD = hud;
        hscriptPath = path;
    }
    public function start(song) {}
    public function beatHit(beat) {}
    public function stepHit(step) {}
    public function playerTwoTurn() {}
    public function playerTwoMiss() {}
    public function playerTwoSing() {}
    public function playerOneTurn() {}
    public function playerOneMiss() {}
    public function playerOneSing() {}

}