package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.Assets;
import sys.io.File;

using flixel.util.FlxSpriteUtil;

class DebugBoundingState extends FlxState
{
	var bg:FlxSprite;
	var fileInfo:FlxText;

	var txtGrp:FlxGroup;

	var hudCam:FlxCamera;

	override function create()
	{
		hudCam = new FlxCamera();
		hudCam.bgColor.alpha = 0;

		FlxG.cameras.add(hudCam, false);

		bg = FlxGridOverlay.create(10, 10);

		bg.scrollFactor.set();
		add(bg);

		var tex = Paths.getSparrowAtlas('characters/temp');
		// tex.frames[0].uv

		var bf:FlxSprite = new FlxSprite();
		bf.loadGraphic(tex.parent);
		add(bf);

		var swagGraphic:FlxSprite = new FlxSprite().makeGraphic(tex.parent.width, tex.parent.height, FlxColor.TRANSPARENT);

		for (i in tex.frames)
		{
			var lineStyle:LineStyle = {color: FlxColor.RED, thickness: 2};

			var uvW:Float = (i.uv.width * i.parent.width) - (i.uv.x * i.parent.width);
			var uvH:Float = (i.uv.height * i.parent.height) - (i.uv.y * i.parent.height);

			// trace(Std.int(i.uv.width * i.parent.width));
			swagGraphic.drawRect(i.uv.x * i.parent.width, i.uv.y * i.parent.height, uvW, uvH, FlxColor.TRANSPARENT, lineStyle);
			// swagGraphic.setPosition(, );
			// trace(uvH);
		}

		txtGrp = new FlxGroup();
		txtGrp.cameras = [hudCam];
		add(txtGrp);

		addInfo('boyfriend.xml', "");
		addInfo('Width', bf.width);
		addInfo('Height', bf.height);

		swagGraphic.antialiasing = true;
		add(swagGraphic);

		FlxG.stage.window.onDropFile.add(function(path:String)
		{
			trace("DROPPED FILE FROM: " + Std.string(path));
			var newPath = "./" + Paths.image('characters/temp');
			File.copy(path, newPath);

			var swag = Paths.image('characters/temp');

			if (bf != null)
				remove(bf);
			FlxG.bitmap.removeByKey(Paths.image('characters/temp'));
			Assets.cache.clear();

			bf.loadGraphic(Paths.image('characters/temp'));
			add(bf);
		});

		super.create();
	}

	function addInfo(str:String, value:Dynamic)
	{
		var swagText:FlxText = new FlxText(10, 10 + (28 * txtGrp.length));
		swagText.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.scrollFactor.set();
		txtGrp.add(swagText);

		swagText.text = str + ": " + Std.string(value);
	}

	override function update(elapsed:Float)
	{
		CoolUtil.mouseCamDrag();
		CoolUtil.mouseWheelZoom();

		// bg.scale.x = FlxG.camera.zoom;
		// bg.scale.y = FlxG.camera.zoom;

		bg.setGraphicSize(Std.int(bg.width / FlxG.camera.zoom));

		super.update(elapsed);
	}
}
