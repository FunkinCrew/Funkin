package ui.stageBuildShit;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import openfl.Assets;

class StageBuilderState extends MusicBeatState
{
	private var hudGrp:FlxGroup;

	private var sprGrp:FlxGroup;

	override function create()
	{
		super.create();

		FlxG.mouse.visible = true;

		// var snd:Sound = new Sound();

		var bg:FlxSprite = FlxGridOverlay.create(10, 10);
		add(bg);

		sprGrp = new FlxGroup();
		add(sprGrp);

		hudGrp = new FlxGroup();
		add(hudGrp);

		var imgBtn:FlxButton = new FlxButton(20, 20, "Load Image", loadImage);
		hudGrp.add(imgBtn);

		var saveSceneBtn:FlxButton = new FlxButton(20, 50, "Save Scene", saveScene);
		hudGrp.add(saveSceneBtn);

		#if desktop
		FlxG.stage.window.onDropFile.add(function(path:String)
		{
			trace("DROPPED FILE FROM: " + Std.string(path));

			var fileName:String = path.split('\\').pop();
			var fileNameNoExt:String = fileName.split('.')[0];

			var newPath = './' + Paths.image('stageBuild/' + fileNameNoExt);
			// sys.io.File.copy(path, newPath);
			// trace(sys.io.File.getBytes(Std.string(path)).toString());

			// FlxG.bitmap.add('assets/preload/images/stageBuild/eltonJohn.png');

			sys.io.File.copy(path, './' + Paths.image('stageBuild/stageTempImg'));

			var fo = sys.io.File.write(newPath);

			fo.write(sys.io.File.getBytes(path));

			new FlxTimer().start(1, function(tmr)
			{
				var awesomeImg:SprStage = new SprStage();
				awesomeImg.loadGraphic(Paths.image('stageBuild/stageTempImg'), false, 0, 0, true);

				sprGrp.add(awesomeImg);
			});

			// Load the image shit by
			// 1. reading the image file names
			// 2. copy to stage temp like normal?

			// var awesomeImg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('stageBuild/swag'));
			// sprGrp.add(awesomeImg);
			// var swag = Paths.image('characters/temp');

			// if (bf != null)
			// remove(bf);
			// FlxG.bitmap.removeByKey(Paths.image('characters/temp'));

			// bf.loadGraphic(Paths.image('characters/temp'));
			// add(bf);
		});
		#end
	}

	function loadImage():Void
	{
		var img:FlxSprite = new FlxSprite().loadGraphic(Paths.image('newgrounds_logo'));
		img.scrollFactor.set(0.5, 2);
		sprGrp.add(img);
	}

	function saveScene():Void
	{
		// trace();
	}

	var oldCamPos:FlxPoint = new FlxPoint();
	var oldMousePos:FlxPoint = new FlxPoint();

	override function update(elapsed:Float)
	{
		if (FlxG.mouse.justPressedMiddle)
		{
			oldCamPos.set(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			oldMousePos.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
		}

		if (FlxG.mouse.pressedMiddle)
		{
			FlxG.camera.scroll.x = oldCamPos.x - (FlxG.mouse.screenX - oldMousePos.x);
			FlxG.camera.scroll.y = oldCamPos.y - (FlxG.mouse.screenY - oldMousePos.y);
		}

		super.update(elapsed);
	}
}
