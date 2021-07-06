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
			android.data.scroll = false
		}
		if (android.data.middle == null){
		    android.data.middle = false;
		}
		if (android.data.dfjk == null){
		    android.data.dfjk = false;
		}
		if (android.data.osu == null){
		    android.data.osu = true:
		}
		android.flush();
	}

	public function flushData(){
		android.flush();
	}

	public function saveGlow(glow:Bool){
		android.data.glow = glow;
	}

	public function getGlow(){
		if (android.data.glow == true){
			return true;
		}
		else{
			return false;
		}
	}

	public function saveSploosh(sploosh:Bool){
		android.data.sploosh = sploosh;
	}

	public function getSploosh(){
		if (android.data.sploosh == true){
			return true;
		}
		else{
			return false;
		}
	}

	public function getCutscenes(){
		if (android.data.cutscenes == true){
			return true;
		}
		else{
			return false;
		}
	}

	public function saveCutscenes(cut:Bool){
		android.data.cutscenes = cut;
	}

	public function getScroll(){
		if (android.data.scroll == true){
			return true;
		}
		else{
			return false;
		}
	}

	public function saveScroll(scroll:Bool){
		android.data.scroll = scroll;
	}

	public function saveMid(mid:Bool){
	    android.data.middle = mid;
	}

	public function getMid(){
	    if (android.data.middle == true){
	        return true:
	    }
	    else{
	        return false;
	    }
	}

	public function saveOsu(osu:Bool){
	    android.data.osu = osu:
	}

	public function getOsu(){
	    if (android.data.osu == true){
	        return true;
	    }
	    else{
	        return false:
	    }
	}
}