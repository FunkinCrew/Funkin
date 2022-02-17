package states;

import lime.app.Application;
import openfl.Assets;
import ui.Alphabet;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.Highscore;
import game.Song;
import game.Replay;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class ReplaySelectorState extends MusicBeatState
{
    var replays:Array<String>;
    static var selected:Int = 0;

    private var grpReplays:FlxTypedGroup<Alphabet>;

    public function new()
    {
        MusicBeatState.windowNameSuffix = " Replays";

        super();
        
        var menuBG:FlxSprite;

		if(utilities.Options.getData("menuBGs"))
			menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		else
			menuBG = new FlxSprite().makeGraphic(1286, 730, FlxColor.fromString("#E1E1E1"), false, "optimizedMenuDesat");

		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

        grpReplays = new FlxTypedGroup<Alphabet>();
        add(grpReplays);

        reloadReplays();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(controls.RESET)
            reloadReplays();

        if(controls.ACCEPT)
        {
            var replay = Replay.loadFromJson(replays[selected]);

            var poop:String = Highscore.formatSong(replay.song, replay.difficulty);

            if(Assets.exists(Paths.json("song data/" + replay.song.toLowerCase() + "/" + poop)))
            {
                PlayState.SONG = Song.loadFromJson(poop, replay.song);
                PlayState.isStoryMode = false;
                PlayState.songMultiplier = replay.songMultiplier;
                PlayState.storyDifficultyStr = replay.difficulty.toUpperCase();
                PlayState.playingReplay = true;
    
                PlayState.chartingMode = false;
                LoadingState.loadAndSwitchState(new PlayState(replay));
            }
            else
                Application.current.window.alert("It seems this replay's song doesn't exist, maybe try enabling the mod for it?", "Leather Engine's No Crash Tool");
        }

        if(controls.DOWN_P)
            changeReplay(1);

        if(controls.UP_P)
            changeReplay(-1);

        if(-1 * Math.floor(FlxG.mouse.wheel) != 0)
            changeReplay(-1 * Math.floor(FlxG.mouse.wheel));

        if(controls.BACK)
            FlxG.switchState(new MainMenuState());
    }

    function reloadReplays()
    {
        selected = 0;

        grpReplays.clear();
        replays = Replay.getReplayList();

        for(i in 0...replays.length)
        {
            var songText:Alphabet = new Alphabet(0, (70 * i) + 30, replays[i], true, false);
            songText.isMenuItem = true;
            songText.targetY = i;
            grpReplays.add(songText);
        }

        changeReplay();
    }

    function changeReplay(change:Int = 0)
    {
        selected += change;

		if (selected < 0)
			selected = replays.length - 1;
		if (selected >= replays.length)
			selected = 0;

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        var bullShit:Int = 0;

        for(item in grpReplays.members)
        {
            item.targetY = bullShit - selected;
            bullShit++;

            item.alpha = 0.6;

            if (item.targetY == 0)
            {
                item.alpha = 1;
            }
        }
    }
}