import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxG;
import funkin.audio.FunkinSound;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.GameOverSubState;

class BoyfriendCharacter extends MultiSparrowCharacter {
	function new() {
		super('bf');
	}

	override function playAnimation(name:String, restart:Bool, ignoreOther:Bool) {
		if (name == "fakeoutDeath" && !this.debug) {
			doFakeoutDeath();
		} else {
			super.playAnimation(name, restart, ignoreOther);
		}
	}

	function doFakeoutDeath():Void {
		FunkinSound.playOnce(Paths.sound("gameplay/gameover/fakeout_death"), 1.0);

		var bfFakeout:FlxAtlasSprite = new FlxAtlasSprite(this.x - 440, this.y - 240, Paths.animateAtlas("characters/bfFakeOut", "shared"));
    FlxG.state.subState.add(bfFakeout);
		bfFakeout.zIndex = 1000;
    bfFakeout.playAnimation('');
		// We don't want people to miss this.
		FlxG.state.subState.mustNotExit = true;
    bfFakeout.onAnimationComplete.add(() -> {
      bfFakeout.visible = false;
      this.visible = true;
			FlxG.state.subState.mustNotExit = false;
      this.playAnimation('firstDeath', true, true);
      // Play the "blue balled" sound. May play a variant if one has been assigned.
      GameOverSubState.playBlueBalledSFX();
    });
    bfFakeout.visible = true;
		this.visible = false;
	}
}
