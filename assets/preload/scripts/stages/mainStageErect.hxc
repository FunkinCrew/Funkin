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

class MainStageErectStage extends Stage
{
	function new()
	{
		super('mainStageErect');
	}

  var colorShaderBf:AdjustColorShader;
  var colorShaderDad:AdjustColorShader;
  var colorShaderGf:AdjustColorShader;

	public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);
	}

	function buildStage()
	{
		super.buildStage();

    colorShaderBf = new AdjustColorShader();
    colorShaderDad = new AdjustColorShader();
    colorShaderGf = new AdjustColorShader();

    colorShaderBf.brightness = -23;
    colorShaderBf.hue = 12;
    colorShaderBf.contrast = 7;
		colorShaderBf.saturation = 0;

    colorShaderGf.brightness = -30;
    colorShaderGf.hue = -9;
    colorShaderGf.contrast = -4;
		colorShaderGf.saturation = 0;

    colorShaderDad.brightness = -33;
    colorShaderDad.hue = -32;
    colorShaderDad.contrast = -23;
		colorShaderDad.saturation = 0;

    getNamedProp('brightLightSmall').blend = 0;
    getNamedProp('orangeLight').blend = 0;
    getNamedProp('lightgreen').blend = 0;
    getNamedProp('lightred').blend = 0;
    getNamedProp('lightAbove').blend = 0;

	}

	function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

    if(PlayState.instance.currentStage.getBoyfriend() != null && PlayState.instance.currentStage.getBoyfriend().shader == null){
      PlayState.instance.currentStage.getBoyfriend().shader = colorShaderBf;
			PlayState.instance.currentStage.getGirlfriend().shader = colorShaderGf;
			PlayState.instance.currentStage.getDad().shader = colorShaderDad;
    }

	}

	function onBeatHit(event:SongTimeScriptEvent):Void
	{
		super.onBeatHit(event);
	}

  function onStepHit(event:SongTimeScriptEvent):Void
	{
		super.onStepHit(event);
	}
}
