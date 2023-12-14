package funkin;

import flixel.FlxG;
import flixel.FlxState;
import funkin.Conductor;
import funkin.data.song.SongData.SongTimeChange;
import funkin.util.Constants;
import massive.munit.Assert;

@:nullSafety
@:access(funkin.Conductor)
class ConductorTest extends FunkinTest
{
  var conductorState:Null<ConductorState> = null;

  @Before
  function before()
  {
    FunkinAssert.initAssertTrace();

    resetGame();

    // The ConductorState will advance the conductor when step() is called.
    FlxG.switchState(conductorState = new ConductorState());

    Conductor.reset();
  }

  @Test
  function testDefaultValues():Void
  {
    // NOTE: Expected value comes first.

    Assert.areEqual([], Conductor.instance.timeChanges);
    Assert.areEqual(null, Conductor.instance.currentTimeChange);

    Assert.areEqual(0, Conductor.instance.songPosition);
    Assert.areEqual(Constants.DEFAULT_BPM, Conductor.instance.bpm);
    Assert.areEqual(null, Conductor.instance.bpmOverride);

    Assert.areEqual(600, Conductor.instance.beatLengthMs);

    Assert.areEqual(4, Conductor.instance.timeSignatureNumerator);
    Assert.areEqual(4, Conductor.instance.timeSignatureDenominator);

    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    Assert.areEqual(0.0, Conductor.instance.currentStepTime);

    Assert.areEqual(150, Conductor.instance.stepLengthMs);
  }

  /**
   * Tests implementation of `update()`, and how it affects
   * `currentBeat`, `currentStep`, `currentStepTime`, and the `beatHit` and `stepHit` signals.
   */
  @Test
  function testUpdate():Void
  {
    var currentConductorState:Null<ConductorState> = conductorState;
    Assert.isNotNull(currentConductorState);

    Assert.areEqual(0, Conductor.instance.songPosition);

    step(); // 1

    var BPM_100_STEP_TIME = 1 / 9;

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 1, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(1 / 9, Conductor.instance.currentStepTime);

    step(7); // 8

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 8, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(8 / 9, Conductor.instance.currentStepTime);

    Assert.areEqual(0, currentConductorState.beatsHit);
    Assert.areEqual(0, currentConductorState.stepsHit);

    step(); // 9

    Assert.areEqual(0, currentConductorState.beatsHit);
    Assert.areEqual(1, currentConductorState.stepsHit);
    currentConductorState.beatsHit = 0;
    currentConductorState.stepsHit = 0;

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 9, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(1, Conductor.instance.currentStep);
    FunkinAssert.areNear(1.0, Conductor.instance.currentStepTime);

    step(35 - 9); // 35

    Assert.areEqual(0, currentConductorState.beatsHit);
    Assert.areEqual(2, currentConductorState.stepsHit);
    currentConductorState.beatsHit = 0;
    currentConductorState.stepsHit = 0;

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 35, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(3, Conductor.instance.currentStep);
    FunkinAssert.areNear(3.0 + 8 / 9, Conductor.instance.currentStepTime);

    step(); // 36

    Assert.areEqual(1, currentConductorState.beatsHit);
    Assert.areEqual(1, currentConductorState.stepsHit);
    currentConductorState.beatsHit = 0;
    currentConductorState.stepsHit = 0;

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 36, Conductor.instance.songPosition);
    Assert.areEqual(1, Conductor.instance.currentBeat);
    Assert.areEqual(4, Conductor.instance.currentStep);
    FunkinAssert.areNear(4.0, Conductor.instance.currentStepTime);

    step(50 - 36); // 50

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 50, Conductor.instance.songPosition);
    Assert.areEqual(1, Conductor.instance.currentBeat);
    Assert.areEqual(5, Conductor.instance.currentStep);
    FunkinAssert.areNear(5.555555, Conductor.instance.currentStepTime);

    step(49); // 99

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 99, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(11, Conductor.instance.currentStep);
    FunkinAssert.areNear(11.0, Conductor.instance.currentStepTime);

    step(1); // 100

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 100, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(11, Conductor.instance.currentStep);
    FunkinAssert.areNear(11.111111, Conductor.instance.currentStepTime);
  }

  @Test
  function testUpdateForcedBPM():Void
  {
    Conductor.instance.forceBPM(60);

    Assert.areEqual(0, Conductor.instance.songPosition);

    // 60 beats per minute = 1 beat per second
    // 1 beat per second = 1/60 beats per frame = 4/60 steps per frame
    step(); // Advances time 1/60 of 1 second.

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 1, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(4 / 60, Conductor.instance.currentStepTime); // 1/60 of 1 beat = 4/60 of 1 step

    step(14 - 1); // 14

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 14, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(1.0 - 4 / 60, Conductor.instance.currentStepTime); // 1/60 of 1 beat = 4/60 of 1 step

    step(); // 15

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 15, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(1, Conductor.instance.currentStep);
    FunkinAssert.areNear(1.0, Conductor.instance.currentStepTime); // 1/60 of 1 beat = 4/60 of 1 step

    step(45 - 1); // 59

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 59, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(3, Conductor.instance.currentStep);
    FunkinAssert.areNear(4.0 - 4 / 60, Conductor.instance.currentStepTime);

    step(); // 60

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 60, Conductor.instance.songPosition);
    Assert.areEqual(1, Conductor.instance.currentBeat);
    Assert.areEqual(4, Conductor.instance.currentStep);
    FunkinAssert.areNear(4.0, Conductor.instance.currentStepTime);

    step(); // 61

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 61, Conductor.instance.songPosition);
    Assert.areEqual(1, Conductor.instance.currentBeat);
    Assert.areEqual(4, Conductor.instance.currentStep);
    FunkinAssert.areNear(4.0 + 4 / 60, Conductor.instance.currentStepTime);
  }

  @Test
  function testSingleTimeChange():Void
  {
    // Start the song with a BPM of 120.
    var songTimeChanges:Array<SongTimeChange> = [new SongTimeChange(0, 120)];
    Conductor.instance.mapTimeChanges(songTimeChanges);

    // All should be at 0.
    FunkinAssert.areNear(0, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(0.0, Conductor.instance.currentStepTime); // 2/120 of 1 beat = 8/120 of 1 step

    // 120 beats per minute = 2 beat per second
    // 2 beat per second = 2/60 beats per frame = 16/120 steps per frame
    step(); // Advances time 1/60 of 1 second.

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 1, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(16 / 120, Conductor.instance.currentStepTime); // 2/120 of 1 beat = 8/120 of 1 step

    step(15 - 1); // 15

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 15, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(2, Conductor.instance.currentStep);
    FunkinAssert.areNear(2.0, Conductor.instance.currentStepTime); // 2/60 of 1 beat = 8/60 of 1 step

    step(45 - 1); // 59

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 59, Conductor.instance.songPosition);
    Assert.areEqual(1, Conductor.instance.currentBeat);
    Assert.areEqual(7, Conductor.instance.currentStep);
    FunkinAssert.areNear(7.0 + 104 / 120, Conductor.instance.currentStepTime);

    step(); // 60

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 60, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(8, Conductor.instance.currentStep);
    FunkinAssert.areNear(8.0, Conductor.instance.currentStepTime);

    step(); // 61

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 61, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(8, Conductor.instance.currentStep);
    FunkinAssert.areNear(8.0 + 8 / 60, Conductor.instance.currentStepTime);
  }

  @Test
  function testDoubleTimeChange():Void
  {
    // Start the song with a BPM of 120.
    var songTimeChanges:Array<SongTimeChange> = [new SongTimeChange(0, 120), new SongTimeChange(3000, 90)];
    Conductor.instance.mapTimeChanges(songTimeChanges);

    // All should be at 0.
    FunkinAssert.areNear(0, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(0.0, Conductor.instance.currentStepTime); // 2/120 of 1 beat = 8/120 of 1 step

    // 120 beats per minute = 2 beat per second
    // 2 beat per second = 2/60 beats per frame = 16/120 steps per frame
    step(); // Advances time 1/60 of 1 second.

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 1, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(16 / 120, Conductor.instance.currentStepTime); // 4/120 of 1 beat = 16/120 of 1 step

    step(60 - 1 - 1); // 59

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 59, Conductor.instance.songPosition);
    Assert.areEqual(1, Conductor.instance.currentBeat);
    Assert.areEqual(7, Conductor.instance.currentStep);
    FunkinAssert.areNear(7.0 + 104 / 120, Conductor.instance.currentStepTime);

    step(); // 60

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 60, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(8, Conductor.instance.currentStep);
    FunkinAssert.areNear(8.0, Conductor.instance.currentStepTime);

    step(); // 61

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 61, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(8, Conductor.instance.currentStep);
    FunkinAssert.areNear(8.0 + 8 / 60, Conductor.instance.currentStepTime);

    step(179 - 61); // 179

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 179, Conductor.instance.songPosition);
    Assert.areEqual(5, Conductor.instance.currentBeat);
    Assert.areEqual(23, Conductor.instance.currentStep);
    FunkinAssert.areNear(23.0 + 52 / 60, Conductor.instance.currentStepTime);

    step(); // 180 (3 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 180, Conductor.instance.songPosition);
    Assert.areEqual(6, Conductor.instance.currentBeat);
    Assert.areEqual(24, Conductor.instance.currentStep);
    FunkinAssert.areNear(24.0, Conductor.instance.currentStepTime);

    step(); // 181 (3 + 1/60 seconds)
    // BPM has switched to 90!
    // 90 beats per minute = 1.5 beat per second
    // 1.5 beat per second = 1.5/60 beats per frame = 3/120 beats per frame
    // = 12/120 steps per frame

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 181, Conductor.instance.songPosition);
    Assert.areEqual(6, Conductor.instance.currentBeat);
    Assert.areEqual(24, Conductor.instance.currentStep);
    FunkinAssert.areNear(24.0 + 12 / 120, Conductor.instance.currentStepTime);

    step(59); // 240 (4 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 240, Conductor.instance.songPosition);
    Assert.areEqual(7, Conductor.instance.currentBeat);
    Assert.areEqual(30, Conductor.instance.currentStep);
    FunkinAssert.areNear(30.0, Conductor.instance.currentStepTime);

    step(); // 241 (4 + 1/60 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 241, Conductor.instance.songPosition);
    Assert.areEqual(7, Conductor.instance.currentBeat);
    Assert.areEqual(30, Conductor.instance.currentStep);
    FunkinAssert.areNear(30.0 + 12 / 120, Conductor.instance.currentStepTime);
  }

  @Test
  function testTripleTimeChange():Void
  {
    // Start the song with a BPM of 120, then move to 90, then move to 180.
    var songTimeChanges:Array<SongTimeChange> = [
      new SongTimeChange(0, 120),
      new SongTimeChange(3000, 90),
      new SongTimeChange(6000, 180)
    ];
    Conductor.instance.mapTimeChanges(songTimeChanges);

    // Verify time changes.
    Assert.areEqual(3, Conductor.instance.timeChanges.length);
    FunkinAssert.areNear(0, Conductor.instance.timeChanges[0].beatTime);
    FunkinAssert.areNear(6, Conductor.instance.timeChanges[1].beatTime);
    FunkinAssert.areNear(10.5, Conductor.instance.timeChanges[2].beatTime);

    // All should be at 0.
    FunkinAssert.areNear(0, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(0.0, Conductor.instance.currentStepTime); // 2/120 of 1 beat = 8/120 of 1 step

    // 120 beats per minute = 2 beat per second
    // 2 beat per second = 2/60 beats per frame = 16/120 steps per frame
    step(); // Advances time 1/60 of 1 second.

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 1, Conductor.instance.songPosition);
    Assert.areEqual(0, Conductor.instance.currentBeat);
    Assert.areEqual(0, Conductor.instance.currentStep);
    FunkinAssert.areNear(16 / 120, Conductor.instance.currentStepTime); // 4/120 of 1 beat = 16/120 of 1 step

    step(60 - 1 - 1); // 59

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 59, Conductor.instance.songPosition);
    Assert.areEqual(1, Conductor.instance.currentBeat);
    Assert.areEqual(7, Conductor.instance.currentStep);
    FunkinAssert.areNear(7 + 104 / 120, Conductor.instance.currentStepTime);

    step(); // 60

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 60, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(8, Conductor.instance.currentStep);
    FunkinAssert.areNear(8.0, Conductor.instance.currentStepTime);

    step(); // 61

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 61, Conductor.instance.songPosition);
    Assert.areEqual(2, Conductor.instance.currentBeat);
    Assert.areEqual(8, Conductor.instance.currentStep);
    FunkinAssert.areNear(8.0 + 8 / 60, Conductor.instance.currentStepTime);

    step(179 - 61); // 179

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 179, Conductor.instance.songPosition);
    Assert.areEqual(5, Conductor.instance.currentBeat);
    Assert.areEqual(23, Conductor.instance.currentStep);
    FunkinAssert.areNear(23.0 + 52 / 60, Conductor.instance.currentStepTime);

    step(); // 180 (3 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 180, Conductor.instance.songPosition);
    Assert.areEqual(6, Conductor.instance.currentBeat);
    Assert.areEqual(24, Conductor.instance.currentStep); // 23.999 => 24
    FunkinAssert.areNear(24.0, Conductor.instance.currentStepTime);

    step(); // 181 (3 + 1/60 seconds)
    // BPM has switched to 90!
    // 90 beats per minute = 1.5 beat per second
    // 1.5 beat per second = 1.5/60 beats per frame = 3/120 beats per frame
    // = 12/120 steps per frame

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 181, Conductor.instance.songPosition);
    Assert.areEqual(6, Conductor.instance.currentBeat);
    Assert.areEqual(24, Conductor.instance.currentStep);
    FunkinAssert.areNear(24.0 + 12 / 120, Conductor.instance.currentStepTime);

    step(60 - 1 - 1); // 240 (4 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 239, Conductor.instance.songPosition);
    Assert.areEqual(7, Conductor.instance.currentBeat);
    Assert.areEqual(29, Conductor.instance.currentStep);
    FunkinAssert.areNear(29.0 + 108 / 120, Conductor.instance.currentStepTime);

    step(); // 240 (4 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 240, Conductor.instance.songPosition);
    Assert.areEqual(7, Conductor.instance.currentBeat);
    Assert.areEqual(30, Conductor.instance.currentStep);
    FunkinAssert.areNear(30.0, Conductor.instance.currentStepTime);

    step(); // 241 (4 + 1/60 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 241, Conductor.instance.songPosition);
    Assert.areEqual(7, Conductor.instance.currentBeat);
    Assert.areEqual(30, Conductor.instance.currentStep);
    FunkinAssert.areNear(30.0 + 12 / 120, Conductor.instance.currentStepTime);

    step(359 - 241); // 359 (5 + 59/60 seconds)

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 359, Conductor.instance.songPosition);
    Assert.areEqual(10, Conductor.instance.currentBeat);
    Assert.areEqual(41, Conductor.instance.currentStep);
    FunkinAssert.areNear(41 + 108 / 120, Conductor.instance.currentStepTime);

    step(); // 360

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 360, Conductor.instance.songPosition);
    Assert.areEqual(10, Conductor.instance.currentBeat);
    Assert.areEqual(42, Conductor.instance.currentStep); // 41.999
    FunkinAssert.areNear(42.0, Conductor.instance.currentStepTime);

    step(); // 361
    // BPM has switched to 180!
    // 180 beats per minute = 3 beat per second
    // 3 beat per second = 3/60 beats per frame
    // = 12/60 steps per frame

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 361, Conductor.instance.songPosition);
    Assert.areEqual(10, Conductor.instance.currentBeat);
    Assert.areEqual(42, Conductor.instance.currentStep);
    FunkinAssert.areNear(42.0 + 12 / 60, Conductor.instance.currentStepTime);

    step(); // 362

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 362, Conductor.instance.songPosition);
    Assert.areEqual(10, Conductor.instance.currentBeat);
    Assert.areEqual(42, Conductor.instance.currentStep);
    FunkinAssert.areNear(42.0 + 24 / 60, Conductor.instance.currentStepTime);

    step(3); // 365

    FunkinAssert.areNear(FunkinTest.MS_PER_STEP * 365, Conductor.instance.songPosition);
    Assert.areEqual(10, Conductor.instance.currentBeat);
    Assert.areEqual(43, Conductor.instance.currentStep); // 42.999 => 42
    FunkinAssert.areNear(43.0, Conductor.instance.currentStepTime);
  }
}

class ConductorState extends FlxState
{
  public var beatsHit:Int = 0;
  public var stepsHit:Int = 0;

  public function new()
  {
    super();
  }

  function beatHit():Void
  {
    beatsHit += 1;
  }

  function stepHit():Void
  {
    stepsHit += 1;
  }

  public override function create():Void
  {
    super.create();
    Conductor.beatHit.add(this.beatHit);
    Conductor.stepHit.add(this.stepHit);
  }

  public override function destroy():Void
  {
    super.destroy();
    Conductor.beatHit.remove(this.beatHit);
    Conductor.stepHit.remove(this.stepHit);
  }

  public override function update(elapsed:Float)
  {
    super.update(elapsed);

    // On each step, increment the Conductor as though the song was playing.
    Conductor.instance.update(Conductor.instance.songPosition + elapsed * Constants.MS_PER_SEC);
  }
}
