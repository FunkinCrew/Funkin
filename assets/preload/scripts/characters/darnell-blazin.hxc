import flixel.FlxG;
import funkin.play.PlayState;
import funkin.play.character.AnimateAtlasCharacter;
import StringTools;

class DarnellBlazinCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('darnell-blazin');
	}

	function onCreate(event:ScriptEvent) {
		super.onCreate(event);

		this.danceEvery = 0;
		this.playAnimation('idle', true, false);
	}

	var cantUppercut = false;

	function onNoteHit(event:HitNoteScriptEvent)
	{
		holdTimer = 0;

		if (!StringTools.startsWith(event.note.kind, 'weekend-1-')) return;

		// SPECIAL CASE: If Pico hits a poor note at low health (at 30% chance),
		// Darnell may duck below Pico's punch to attempt an uppercut.
		// TODO: Maybe add a cooldown to this?
		var shouldDoUppercutPrep = wasNoteHitPoorly(event) && isPlayerLowHealth() && FlxG.random.bool(30);

		if (shouldDoUppercutPrep) {
			playUppercutPrepAnim();
			return;
		}

		if (cantUppercut) {
			playPunchHighAnim();
			return;
		}

		// Override the hit note animation.
		switch (event.note.kind)
		{
			case "weekend-1-punchlow":
				playHitLowAnim();
			case "weekend-1-punchlowblocked":
				playBlockAnim();
			case "weekend-1-punchlowdodged":
				playDodgeAnim();
			case "weekend-1-punchlowspin":
				playSpinAnim();

			case "weekend-1-punchhigh":
				playHitHighAnim();
			case "weekend-1-punchhighblocked":
				playBlockAnim();
			case "weekend-1-punchhighdodged":
				playDodgeAnim();
			case "weekend-1-punchhighspin":
				playSpinAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-blockhigh":
				playPunchHighAnim();
			case "weekend-1-blocklow":
				playPunchLowAnim();
			case "weekend-1-blockspin":
				playPunchHighAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-dodgehigh":
				playPunchHighAnim();
			case "weekend-1-dodgelow":
				playPunchLowAnim();
			case "weekend-1-dodgespin":
				playPunchHighAnim();

			// Attempt to punch, Pico ALWAYS gets hit.
			case "weekend-1-hithigh":
				playPunchHighAnim();
			case "weekend-1-hitlow":
				playPunchLowAnim();
			case "weekend-1-hitspin":
				playPunchHighAnim();

			// Fail to dodge the uppercut.
			case "weekend-1-picouppercutprep":
				// Continue whatever animation was playing before
				// playIdleAnim();
			case "weekend-1-picouppercut":
				playUppercutHitAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-darnelluppercutprep":
				playUppercutPrepAnim();
			case "weekend-1-darnelluppercut":
				playUppercutAnim();

			case "weekend-1-idle":
				playIdleAnim();
			case "weekend-1-fakeout":
				playCringeAnim();
			case "weekend-1-taunt":
				playPissedConditionalAnim();
			case "weekend-1-tauntforce":
				playPissedAnim();
			case "weekend-1-reversefakeout":
				playFakeoutAnim();

			default:
				trace('Unknown note kind: ' + event.note.kind);
		}

		cantUppercut = false;
	}

	function onNoteMiss(event:NoteScriptEvent)
	{
		holdTimer = 0;

		if (!StringTools.startsWith(event.note.kind, 'weekend-1-')) {
			return;
		}

		// SPECIAL CASE: Darnell prepared to uppercut last time and Pico missed! FINISH HIM!
		if (getCurrentAnimation() == 'uppercutPrep') {
			playUppercutAnim();
			return;
		}

		if (willMissBeLethal(event)) {
			playPunchLowAnim();
			return;
		}

		if (cantUppercut) {
			playPunchHighAnim();
			return;
		}

		// Override the hit note animation.
		switch (event.note.kind)
		{
			// Pico tried and failed to punch, punch back!
			case "weekend-1-punchlow":
				playPunchLowAnim();
			case "weekend-1-punchlowblocked":
				playPunchLowAnim();
			case "weekend-1-punchlowdodged":
				playPunchLowAnim();
			case "weekend-1-punchlowspin":
				playPunchLowAnim();

			// Pico tried and failed to punch, punch back!
			case "weekend-1-punchhigh":
				playPunchHighAnim();
			case "weekend-1-punchhighblocked":
				playPunchHighAnim();
			case "weekend-1-punchhighdodged":
				playPunchHighAnim();
			case "weekend-1-punchhighspin":
				playPunchHighAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-blockhigh":
				playPunchHighAnim();
			case "weekend-1-blocklow":
				playPunchLowAnim();
			case "weekend-1-blockspin":
				playPunchHighAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-dodgehigh":
				playPunchHighAnim();
			case "weekend-1-dodgelow":
				playPunchLowAnim();
			case "weekend-1-dodgespin":
				playPunchHighAnim();

			// Attempt to punch, Pico ALWAYS gets hit.
			case "weekend-1-hithigh":
				playPunchHighAnim();
			case "weekend-1-hitlow":
				playPunchLowAnim();
			case "weekend-1-hitspin":
				playPunchHighAnim();

			// Successfully dodge the uppercut.
			case "weekend-1-picouppercutprep":
				playHitHighAnim();
				cantUppercut = true;
			case "weekend-1-picouppercut":
				playDodgeAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-darnelluppercutprep":
				playUppercutPrepAnim();
			case "weekend-1-darnelluppercut":
				playUppercutAnim();

			case "weekend-1-idle":
				playIdleAnim();
			case "weekend-1-fakeout":
				playCringeAnim(); // TODO: Which anim?
			case "weekend-1-taunt":
				playPissedConditionalAnim();
			case "weekend-1-tauntforce":
				playPissed();
			case "weekend-1-reversefakeout":
				playFakeoutAnim(); // TODO: Which anim?

			default:
				trace('Unknown note kind: ' + event.note.kind);
		}

		cantUppercut = false;
	}

	override function onSongRetry()
	{
		super.onSongRetry();
		cantUppercut = false;
		playIdleAnim();
	}

	function willMissBeLethal(event:NoteScriptEvent):Bool {
		return (PlayState.instance.health + event.healthChange) <= 0.0;
	}

	function onNoteGhostMiss(event:GhostMissNoteScriptEvent)
	{
		if (willMissBeLethal(event)) {
			// Darnell alternates a punch so that Pico dies.
			playPunchLowAnim();
		} else {
			// Pico wildly throws punches but Darnell alternates between dodges and blocks.
			var shouldDodge = FlxG.random.bool(50); // 50/50.
			if (shouldDodge) {
				playDodgeAnim();
			} else {
				playBlockAnim();
		}
		}
	}

	override function onAnimationFinished(name:String)
	{
		super.onAnimationFinished(name);
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

	function playBlockAnim()
	{
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

	function playPissedConditionalAnim()
	{
		if (getCurrentAnimation() == "cringe") {
			playPissedAnim();
		} else {
			playIdleAnim();
		}
	}

	function playPissedAnim()
	{
		this.playAnimation('pissed', true, false);
		moveToBack();
	}

	function playUppercutPrepAnim()
	{
		this.playAnimation('uppercutPrep', true, false);
		moveToFront();
	}

	function playUppercutAnim()
	{
		this.playAnimation('uppercut', true, false);
		moveToFront();
	}

	function playUppercutHitAnim()
	{
		this.playAnimation('uppercutHit', true, false);
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

	function playSpinAnim()
	{
		this.playAnimation('hitSpin', true, false);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}
}
