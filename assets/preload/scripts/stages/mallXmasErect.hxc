import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxRuntimeShader;
import flixel.sound.FlxSound;
import funkin.Conductor;
import funkin.modding.base.ScriptedFlxRuntimeShader;
import funkin.graphics.shaders.AdjustColorShader;
import funkin.play.PlayState;
import funkin.play.stage.Stage;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.modding.base.ScriptedFlxAtlasSprite;
import flixel.FlxG;

class MallXmasErectStage extends Stage
{
	function new()
	{
		super('mallXmasErect');
	}

	var colorShader:AdjustColorShader;

	function onCreate(event:ScriptEvent):Void {
		super.onCreate(event);

		// Create a single color shader and reuse it.
    colorShader = new AdjustColorShader();
		colorShader.hue = 5;
		colorShader.saturation = 20;

		getNamedProp('santa').shader = colorShader;
	}

	override function addCharacter(character:BaseCharacter, charType:CharacterType):Void {
		// Apply the shader automatically to each character as it gets added.
		super.addCharacter(character, charType);
		trace('Applied stage shader to ' + character.characterName);
		character.shader = colorShader;
	}
}
