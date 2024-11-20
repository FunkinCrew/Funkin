import funkin.play.PlayState;
import funkin.play.stage.Stage;
import funkin.graphics.shaders.WiggleEffectRuntime;
import funkin.graphics.shaders.WiggleEffectType;
import flixel.addons.effects.FlxTrail;
import funkin.play.Countdown;

class SchoolEvilStage extends Stage
{
	function new()
	{
		super('schoolEvil');
	}

	var wiggle:FlxRuntimeShader = null;

	override function buildStage()
	{
		super.buildStage();

		wiggle = new WiggleEffectRuntime(2, 4, 0.017, WiggleEffectType.DREAMY);

		getNamedProp('evilSchoolBG').shader = wiggle;
		getNamedProp('evilSchoolFG').shader = wiggle;
	}

	override function addCharacter(char:BaseCharacter, charType:CharacterType)
	{

		super.addCharacter(char, charType);
	}

	override function onUpdate(event:UpdateScriptEvent) {
		super.onUpdate(event);

		if (wiggle != null) {
			wiggle.update(event.elapsed);
		}
	}

	function kill() {
		super.kill();
		wiggle = null;
	}
}
