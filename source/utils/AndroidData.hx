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
	}
}