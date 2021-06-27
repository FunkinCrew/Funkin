package fmf.songs;

import fmf.songs.*;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import fmf.characters.*;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import Song.SwagSong;

// base class execute song data
class SongPlayer extends  BaseSong
{

	// update function
	public function update(elapsed:Float):Void {}
	
	// mid song event update
	public function midSongEventUpdate(curBeat:Int):Void{} 

	// update camera follow dad depending on song
	public function updateCamFollowDad():Void{}

	// update camera follow bf depending on song
	public function updateCamFollowBF():Void{} 
	
	//which map should be load,if you are not override this, it will load default map.
	private override function loadMap():Void{ super.loadMap();}

	//create characters, basically it will create gf, bf, dad 
	private override function createCharacters():Void{ super.createCharacters();}

	//get bf version, if you want to create special behaviour for bf, here you go.	
	private override function getBFVersion():Character{ return super.getBFVersion(); }
	//get texture of bf and set into bf itself
	private override function getBFTex():Void { super.getBFTex(); };
	//create animations for bf
	private override function createBFAnimations():Void{ super.createBFAnimations();}
	//create animation offsets for bf
	private override function createBFAnimationOffsets():Void{ super.createBFAnimationOffsets();}


	//basically same as BF
	private override function getDadVersion():Character{ return super.getDadVersion(); }
	private override function getDadTex():Void { super.getDadTex(); };
	private override function createDadAnimations():Void{ super.createDadAnimations();}
	private override function createDadAnimationOffsets():Void{ super.createDadAnimationOffsets();}
	
	// basically same as BF
	private override function getGFVersion():Character{ return super.getGFVersion(); }
	private override function getGFTex():Void { super.getGFTex(); };
	private override function createGFAnimations():Void{ super.createGFAnimations();}
	private override function createGFAnimationOffsets():Void{ super.createGFAnimationOffsets();}




}