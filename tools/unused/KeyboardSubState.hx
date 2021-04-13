package options;

import flixel.addons.ui.FlxButtonPlus;
import flixel.FlxG;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIButton;

// openSubState(new KeyboardSubState());
class KeyboardSubState extends MusicBeatSubstate
{
	var input:TextField;

	public function new()
	{
		input = new openfl.text.TextField();
		input.x = 0;
		input.y = 0;
		input.type = openfl.text.TextFieldType.INPUT;
		input.textColor = 0x000000;
		input.border = true;
		input.borderColor = 0xFFFF00;
		input.background = true;
		input.backgroundColor = 0xFFFFFF;
		input.width = FlxG.width;
		input.height = FlxG.height;
		input.defaultTextFormat = new openfl.text.TextFormat(null, 32);
		input.needsSoftKeyboard = true;
		input.maxChars = 256;

		
		input.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) -> {
            if (e.keyCode == 13) {
                trace(input.text);
                FlxG.removeChild(input);
                close();
            }
        });

		FlxG.addChildBelowMouse(input);
		FlxG.stage.focus = input;

        super();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		#if android
		if (FlxG.android.justReleased.BACK == true){
			trace(input.text);
            FlxG.removeChild(input);
            close();
		}
		#end
	}

	override function destroy()
	{
		super.destroy();
	}
}
