import funkin.play.PlayState;
import funkin.play.stage.Stage;

class SchoolStage extends Stage
{
	function new()
	{
		super('school');
	}

	function buildStage()
	{
		super.buildStage();

		if (PlayState.instance.currentSong.id.toLowerCase() == "roses")
		{
			getNamedProp('freaks').idleSuffix = '-scared';
		} else {
			getNamedProp('freaks').idleSuffix = '';
		}
	}
}
