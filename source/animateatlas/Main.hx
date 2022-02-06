package;

import animateatlas.JSONData.AtlasData;
import openfl.display.BitmapData;
import animateatlas.JSONData.AnimationData;
import openfl.display.FPS;
import openfl.Lib;
import openfl.events.MouseEvent;
import animateatlas.HelperEnums.LoopMode;
import openfl.events.Event;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.Assets;
import haxe.Json;
import animateatlas.tilecontainer.TileAnimationLibrary;
import animateatlas.tilecontainer.TileContainerMovieClip;
import animateatlas.displayobject.SpriteAnimationLibrary;
import animateatlas.displayobject.SpriteMovieClip;
import openfl.display.Sprite;

class Main extends Sprite {
	var aa:TileAnimationLibrary;
	var ss:SpriteAnimationLibrary;

	//
	var tileSymbols:Array<TileContainerMovieClip>;

	var spriteSymbols:Array<SpriteMovieClip>;

	var renderer:Tilemap;

	public function new() {
		super();
		graphics.beginFill(0x333333);
		graphics.drawRect(0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);

		var animationData:AnimationData = Json.parse(Assets.getText("assets/TEST/Animation.json"));
		var atlasData:AtlasData = Json.parse(Assets.getText("assets/TEST/spritemap.json"));
		var bitmapData:BitmapData = Assets.getBitmapData("assets/TEST/spritemap.png");

		aa = new TileAnimationLibrary(animationData, atlasData, bitmapData);
		ss = new SpriteAnimationLibrary(animationData, atlasData, bitmapData);

		renderer = new Tilemap(Lib.current.stage.stageWidth, Lib.current.stage.stageHeight, null, true);

		renderer.tileAlphaEnabled = false;
		renderer.tileBlendModeEnabled = false;
		renderer.tileColorTransformEnabled = false;

		addChild(renderer);
		addChild(new FPS(10, 10, 0xFFFFFF));

		tileSymbols = [];
		spriteSymbols = [];

		addEventListener(Event.ENTER_FRAME, update);
		// addEventListener(MouseEvent.CLICK, addSpriteGirl);
		addEventListener(MouseEvent.CLICK, addTileGirl);
	}

	var prev:Int = 0;
	var dt:Int = 0;
	var curr:Int = 0;

	public function update(_) {
		// making a dt
		curr = Lib.getTimer();
		dt = curr - prev;
		prev = curr;

		for (symbol in tileSymbols) {
			symbol.update(dt);
		}
		for (symbol in spriteSymbols) {
			symbol.update(dt);
		}
	}

	public function addSpriteGirl(_) {
		for (i in 0...1) {
			var t = ss.createAnimation();
			t.x = mouseX + i * 20 * (-1 * i % 2);
			t.y = mouseY + i * 20 * (-1 * i % 2);

			addChild(t);
			t.loopMode = LoopMode.SINGLE_FRAME;

			t.currentLabel = t.getFrameLabels()[Std.random(t.getFrameLabels().length)];
			spriteSymbols.push(t);
			trace(spriteSymbols.length);
		}
	}

	public function addTileGirl(_) {
		for (i in 0...1) {
			var t = aa.createAnimation();
			t.x = mouseX + i * 5 * (-1 * i % 2);
			t.y = mouseY + i * 5 * (-1 * i % 2);

			renderer.addTile(t);
			t.loopMode = LoopMode.SINGLE_FRAME;

			t.currentLabel = t.getFrameLabels()[Std.random(t.getFrameLabels().length)];
			tileSymbols.push(t);

			trace(tileSymbols.length);
		}
	}
}
