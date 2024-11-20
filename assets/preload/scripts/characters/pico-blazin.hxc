
import flixel.FlxG;
import flixel.util.FlxTimer;
import funkin.play.PlayState;
import funkin.play.PauseSubState;
import funkin.graphics.FunkinSprite;
import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.GameOverSubState;
import StringTools;

class PicoBlazinCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('pico-blazin');
	}

	function onCreate(event:ScriptEvent)
	{
		super.onCreate(event);

		this.danceEvery = 0;
		this.playAnimation('idle', true, false);

		// NOTE: this.x and this.y are not properly set here.

		GameOverSubState.musicSuffix = '-pico';
		GameOverSubState.blueBallSuffix = '-pico-gutpunch';

		PauseSubState.musicSuffix = '-pico';
	}

	var cantUppercut = false;

	function onNoteHit(event:HitNoteScriptEvent)
	{
		holdTimer = 0;

		if (!StringTools.startsWith(event.note.kind, 'weekend-1-')) return;

		// SPECIAL CASE: If Pico hits a poor note at low health (at 30% chance),
		// Pico may instead punch high (but Darnell will duck below Pico to attempt an uppercut)
		// TODO: Maybe add a cooldown to this?
		// NOTE: This relies on scripts dispatching to opponents first, which is true at time of writing.
		var shouldDoUppercutPrep = wasNoteHitPoorly(event) && isPlayerLowHealth() && isDarnellPreppingUppercut();

		if (shouldDoUppercutPrep) {
			playPunchHighAnim();
			return;
		}

		if (cantUppercut) {
			playBlockAnim();
			cantUppercut = false;
			return;
		}

		// Override the hit note animation.
		switch (event.note.kind)
		{
			case "weekend-1-punchlow":
				playPunchLowAnim();
			case "weekend-1-punchlowblocked":
				playPunchLowAnim();
			case "weekend-1-punchlowdodged":
				playPunchLowAnim();
			case "weekend-1-punchlowspin":
				playPunchLowAnim();

			case "weekend-1-punchhigh":
				playPunchHighAnim();
			case "weekend-1-punchhighblocked":
				playPunchHighAnim();
			case "weekend-1-punchhighdodged":
				playPunchHighAnim();
			case "weekend-1-punchhighspin":
				playPunchHighAnim();

			case "weekend-1-blockhigh":
				playBlockAnim(event.judgement);
			case "weekend-1-blocklow":
				playBlockAnim(event.judgement);
			case "weekend-1-blockspin":
				playBlockAnim(event.judgement);

			case "weekend-1-dodgehigh":
				playDodgeAnim();
			case "weekend-1-dodgelow":
				playDodgeAnim();
			case "weekend-1-dodgespin":
				playDodgeAnim();

			// Pico ALWAYS gets punched.
			case "weekend-1-hithigh":
				playHitHighAnim();
			case "weekend-1-hitlow":
				playHitLowAnim();
			case "weekend-1-hitspin":
				playHitSpinAnim();

			case "weekend-1-picouppercutprep":
				playUppercutPrepAnim();
			case "weekend-1-picouppercut":
				playUppercutAnim(true);

			case "weekend-1-darnelluppercutprep":
				playIdleAnim();
			case "weekend-1-darnelluppercut":
				playUppercutHitAnim();

			case "weekend-1-idle":
				playIdleAnim();
			case "weekend-1-fakeout":
				playFakeoutAnim();
			case "weekend-1-taunt":
				playTauntConditionalAnim();
			case "weekend-1-tauntforce":
				playTauntAnim();
			case "weekend-1-reversefakeout":
				playIdleAnim(); // TODO: Which anim?

			default:
				// trace('Unknown note kind: ' + event.note.kind);
		}
	}

	function playAnimation(name:String, restart:Bool, ignoreOther:Bool) {
		if (name == "firstDeath") {
			// TODO: ACTUALLY play one of the three death animations here.

			// Make sure the death music plays with PERFECT timing.
			new FlxTimer().start(1.25, afterPicoDeathGutPunchIntro);
		} else if (name == "deathConfirm") {
			doDeathConfirm();
		} else {
			super.playAnimation(name, restart, ignoreOther);
		}

		super.playAnimation(name, restart, ignoreOther);
	}

	function afterPicoDeathGutPunchIntro():Void {
		GameOverSubState.instance.startDeathMusic(1.0, false);
		playAnimation('deathLoop', true, false);
	}

	function doDeathConfirm():Void {
		var picoDeathConfirm:FunkinSprite = FunkinSprite.createSparrow(this.x + 905, this.y + 1030, 'picoBlazinDeathConfirm');
		picoDeathConfirm.animation.addByPrefix('confirm', "Pico Gut Punch Death0", 24, false);
		picoDeathConfirm.animation.play('confirm');
		picoDeathConfirm.scale.set(1.75, 1.75);
		picoDeathConfirm.zIndex = 1000;
    FlxG.state.subState.add(picoDeathConfirm);
		picoDeathConfirm.visible = true;
		this.visible = false;

		picoDeathConfirm.animation.finishCallback = () -> {
			picoDeathConfirm.visible = false;
			this.visible = true;
		}
	}

	function onNoteMiss(event:NoteScriptEvent)
	{
		holdTimer = 0;

		// SPECIAL CASE: Darnell prepared to uppercut last time and Pico missed! FINISH HIM!
		if (isDarnellInUppercut()) {
			playUppercutHitAnim();
			return;
		}

		if (willMissBeLethal(event)) {
			playHitLowAnim();
			return;
		}

		if (cantUppercut) {
			playHitHighAnim();
			return;
		}

		// Override the hit note animation.
		switch (event.note.kind)
		{
			// Pico fails to punch, and instead gets hit!
			case "weekend-1-punchlow":
				playHitLowAnim();
			case "weekend-1-punchlowblocked":
				playHitLowAnim();
			case "weekend-1-punchlowdodged":
				playHitLowAnim();
			case "weekend-1-punchlowspin":
				playHitSpinAnim();

			// Pico fails to punch, and instead gets hit!
			case "weekend-1-punchhigh":
				playHitHighAnim();
			case "weekend-1-punchhighblocked":
				playHitHighAnim();
			case "weekend-1-punchhighdodged":
				playHitHighAnim();
			case "weekend-1-punchhighspin":
				playHitSpinAnim();

			// Pico fails to block, and instead gets hit!
			case "weekend-1-blockhigh":
				playHitHighAnim();
			case "weekend-1-blocklow":
				playHitLowAnim();
			case "weekend-1-blockspin":
				playHitSpinAnim();

			// Pico fails to dodge, and instead gets hit!
			case "weekend-1-dodgehigh":
				playHitHighAnim();
			case "weekend-1-dodgelow":
				playHitLowAnim();
			case "weekend-1-dodgespin":
				playHitSpinAnim();

			// Pico ALWAYS gets punched.
			case "weekend-1-hithigh":
				playHitHighAnim();
			case "weekend-1-hitlow":
				playHitLowAnim();
			case "weekend-1-hitspin":
				playHitSpinAnim();

			// Fail to dodge the uppercut.
			case "weekend-1-picouppercutprep":
				playPunchHighAnim();
				cantUppercut = true;
			case "weekend-1-picouppercut":
				playUppercutAnim(false);

			// Darnell's attempt to uppercut, Pico dodges or gets hit.
			case "weekend-1-darnelluppercutprep":
				playIdleAnim();
			case "weekend-1-darnelluppercut":
				playUppercutHitAnim();

			case "weekend-1-idle":
				playIdleAnim();
			case "weekend-1-fakeout":
				playHitHighAnim();
			case "weekend-1-taunt":
				playTauntConditionalAnim();
			case "weekend-1-tauntforce":
				playTauntAnim();
			case "weekend-1-reversefakeout":
				playIdleAnim();

			default:
				trace('Unknown note kind: ' + event.note.kind);
		}
	}

	function willMissBeLethal(event:NoteScriptEvent):Bool {
		return (PlayState.instance.health + event.healthChange) <= 0.0;
	}

	function onNoteGhostMiss(event:GhostMissNoteScriptEvent)
	{
		if (willMissBeLethal(event)) {
			// Darnell throws a punch so that Pico dies.
			playHitLowAnim();
		} else {
			// Pico wildly throws punches but Darnell dodges.
			playPunchHighAnim();
		}
	}

	override function onAnimationFinished(name:String)
	{
		super.onAnimationFinished(name);
	}

	override function onSongRetry()
	{
		super.onSongRetry();
		cantUppercut = false;
		playIdleAnim();

		GameOverSubState.musicSuffix = '-pico';
		GameOverSubState.blueBallSuffix = '-pico-gutpunch';

		PauseSubState.musicSuffix = '-pico';
	}

	function getDarnell()
	{
		if (this.debug) return null;
		return PlayState.instance.currentStage.getDad();
	}

	function moveToBack()
	{
		if (this.debug) return;
		this.zIndex = 2000;
		PlayState.instance.currentStage.refresh();
	}

	function moveToFront()
	{
		if (this.debug) return;
		this.zIndex = 3000;
		PlayState.instance.currentStage.refresh();
	}

	function isDarnellPreppingUppercut():Void {
		return getDarnell().getCurrentAnimation() == 'uppercutPrep';
	}

	function isDarnellInUppercut():Void {
		return
			getDarnell().getCurrentAnimation() == 'uppercut'
			|| getDarnell().getCurrentAnimation() == 'uppercut-hold';
	}

	function wasNoteHitPoorly(event:HitNoteScriptEvent):Bool {
		return (event.judgement == "bad" || event.judgement == "shit");
	}

	function isPlayerLowHealth(event:HitNoteScriptEvent):Bool {
		return PlayState.instance.health <= 0.30 * 2.0;
	}

	// ANIMATIONS

	var alternate:Bool = false;

	function doAlternate():String {
		alternate = !alternate;
		return alternate ? '1' : '2';
	}

	function playBlockAnim(?judgement:String)
	{
		// on sick block, do a 3rd strike esque "tech" effect
		if (judgement == 'sick')
		{
			//var blendAnims:Array<Int> = [10, 0, 10, 0, 0, 10, 0, 0, 10, 0, 10];
//
			//for (blendMode in 0...blendAnims.length)
			//{
			//	new FlxTimer().start(blendMode / 60, function(_) {
//
			//		if (blendAnims[blendMode] != 10)
			//			this.color = 0xFF0000FF;
			//		else
			//			this.color = 0xFFFFFFFF;
//
			//		this.blend = blendAnims[blendMode];
			//	});
			//}

		}

		this.playAnimation('block', true, false);
		PlayState.instance.camGame.shake(0.002, 0.1);
		moveToBack();
	}

	function playCringeAnim()
	{
		this.playAnimation('cringe', true, false);
		moveToBack();
	}

	function playDodgeAnim()
	{
		this.playAnimation('dodge', true, false);
		moveToBack();
	}

	function playIdleAnim()
	{
		this.playAnimation('idle', false, false);
		moveToBack();
	}

	function playFakeoutAnim()
	{
		this.playAnimation('fakeout', true, false);
		moveToBack();
	}

	function playUppercutPrepAnim()
	{
		this.playAnimation('uppercutPrep', true, false);
		moveToFront();
	}

	function playUppercutAnim(hit:Bool)
	{
		this.playAnimation('uppercut', true, false);
		if (hit) {
			PlayState.instance.camGame.shake(0.005, 0.25);
		}
		moveToFront();
	}

	function playUppercutHitAnim()
	{
		this.playAnimation('uppercutHit', true, false);
		PlayState.instance.camGame.shake(0.005, 0.25);
		moveToBack();
	}

	function playHitHighAnim()
	{
		this.playAnimation('hitHigh', true, false);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitLowAnim()
	{
		this.playAnimation('hitLow', true, false);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitSpinAnim()
	{
		this.playAnimation('hitSpin', true, false, true);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function playPunchHighAnim()
	{
		this.playAnimation('punchHigh' + doAlternate(), true, false);
		moveToFront();
	}

	function playPunchLowAnim()
	{
		this.playAnimation('punchLow' + doAlternate(), true, false);
		moveToFront();
	}

	function playTauntConditionalAnim()
	{
		if (getCurrentAnimation() == "fakeout") {
			playTauntAnim();
		} else {
			playIdleAnim();
		}
	}

	function playTauntAnim()
	{
		this.playAnimation('taunt', true, false);
		moveToBack();
	}
}
