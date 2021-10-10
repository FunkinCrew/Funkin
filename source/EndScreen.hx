package;

import flixel.addons.api.FlxGameJolt;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxState;

class EndScreen extends MusicBeatState {
    public static var whereGo:Int;

    var mainTxt:FlxText;
    var pressEnter:FlxText;

    public static var sicks:Int;
    public static var goods:Int;
    public static var bads:Int;
    public static var shits:Int;
    public static var misses:Int;
    public static var score:Int;
    public static var rating:String;

    public override function create() {

        FlxG.sound.music.stop();
        FlxG.sound.playMusic(Paths.music('breakfast', 'shared'), 0);
        FlxG.sound.music.fadeIn(4, 0, 0.7);

        transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

        mainTxt = new FlxText(5, 5, 0, '', 32);
        mainTxt.text = '${PlayState.isStoryMode ? 'WEEK' : 'SONG'} CLEARED!\n\n'
        + 'JUGEMENTS:\n'
        + 'Sicks: ${sicks}\n'
        + 'Goods: ${goods}\n'
        + 'Bads: ${bads}\n'
        + 'Shits: ${shits}\n'
        + 'Misses: ${misses}\n'
        + 'SCORE: ${score}\n'
        + 'Rating: ${rating}\n\n'
        + 'Hit ${sicks + goods + bads + shits}/${misses + sicks + goods + bads + shits}\n\n'
        + '${whereGo != 0 ? '${PlayState.SONG.song}:${PlayState.difString}' : 'Week ${PlayState.storyWeek}:${PlayState.difString}'} (${PlayState.curGM.toUpperCase()})';

        pressEnter = new FlxText(0, FlxG.height - 50, 0, 'Press ENTER to Continue', 32);
        pressEnter.screenCenter(X);
        new FlxTimer().start(1, (thing:FlxTimer) -> {
            pressEnter.visible = !pressEnter.visible;
        }, 0);

        add(mainTxt);
        add(pressEnter);

        if (PlayState.isStoryMode) {
            switch (PlayState.storyWeek) {
                case 0:
                    FlxGameJolt.addTrophy(147875);
                case 1:
                    FlxGameJolt.addTrophy(147876);
                case 2:
                    FlxGameJolt.addTrophy(147877);
                case 3:
                    FlxGameJolt.addTrophy(147878);
                case 4:
                    FlxGameJolt.addTrophy(147879);
                case 5:
                    FlxGameJolt.addTrophy(147880);
                case 6:
                    FlxGameJolt.addTrophy(147881);
            }
        }

        FlxGameJolt.addScore('${PlayState.isStoryMode ? '${PlayState.campaignScore} Week Points' : '${score} Points'}', PlayState.isStoryMode ? PlayState.campaignScore : score, 652366, true, "GUEST");
    }

    public override function update(elapsed:Float) {
        if (FlxG.keys.justPressed.ENTER) {
            sicks = 0;
            goods = 0;
            bads = 0;
            shits = 0;
            misses = 0;
            score = 0;

            switch (whereGo) {
                case 0:
                    FlxG.switchState(new StoryMenuState());
                case 1:
                    FlxG.switchState(new FreeplayState());
            }
        }
    }
}