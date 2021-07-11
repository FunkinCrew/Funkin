package utils;

import ui.FlxVirtualPad;
import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

class AndroidData{
	var android:FlxSave;
	public function new(){
		android = new FlxSave();
		android.bind("android-data");
	}

	public function startData(){
		if (android.data.cutscenes == null){
			android.data.cutscenes = true;
		}
		if (android.data.sploosh == null){
			android.data.sploosh = true;
		}
		if (android.data.glow == null){
			android.data.glow = false;
		}
		if (android.data.scroll == null){
			android.data.scroll = false;
		}
		if (android.data.middle == null){
			android.data.middle = false;
		}
		if (android.data.dfjk == null){
			android.data.dfjk = false;
		}
		if (android.data.osu == null){
			android.data.osu = false;
		}
		if (android.data.icon2 == null){
		    android.data.icon2 = false;
		}
		android.flush();
	}

	public function flushData(){
		android.flush();
	}

	public function saveGlow(glow:Bool){
		android.data.glow = glow;
	}

	public function getGlow():Bool{
		return android.data.glow;
	}

	public function saveSploosh(sploosh:Bool){
		android.data.sploosh = sploosh;
	}

	public function getSploosh():Bool{
		return android.data.sploosh;
	}

	public function getCutscenes():Bool{
		return android.data.cutscenes;
	}

	public function saveCutscenes(cut:Bool){
		android.data.cutscenes = cut;
	}

	public function getScroll():Bool{
		return android.data.scroll;
	}

	public function saveScroll(scroll:Bool){
		android.data.scroll = scroll;
	}

	public function saveMid(mid:Bool){
		android.data.middle = mid;
	}

	public function getMid():Bool{
		return android.data.middle;
	}

	public function saveOsu(osu:Bool){
		android.data.osu = osu;
	}

	public function getOsu():Bool{
		return android.data.osu;
	}

	public function saveDfjk(dfjk:Bool){
		android.data.dfjk = dfjk;
	}

	public function getDfjk():Bool{
		return android.data.dfjk;
	}

	public function saveIcon(icon:Bool){
	    android.data.icon2 = icon;
	}

	public function getIcon():Bool{
	    return android.data.icon2;
	}
}