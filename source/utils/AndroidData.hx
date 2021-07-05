package;

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
}