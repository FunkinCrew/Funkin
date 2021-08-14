package;
import haxe.Exception;
#if sys
import smTools.SMFile;
import sys.FileSystem;
import sys.io.File;
#end
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import flixel.system.FlxSound;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import io.newgrounds.NG;
import lime.app.Application;
import lime.utils.Assets;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;


using StringTools;

class ResultsScreen extends FlxSubState
{
    public var background:FlxSprite;
    public var text:FlxText;

    public var anotherBackground:FlxSprite;
    public var graph:HitGraph;
    public var graphSprite:OFLSprite;

    public var comboText:FlxText;
    public var contText:FlxText;
    public var settingsText:FlxText;

    public var music:FlxSound;

    public var graphData:BitmapData;

    public var ranking:String;
    public var accuracy:String;

	override function create()
	{	
        background = new FlxSprite(0,0).makeGraphic(FlxG.width,FlxG.height,FlxColor.BLACK);
        background.scrollFactor.set();
        add(background);

        if (!PlayState.inResults) 
        {
            music = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
            music.volume = 0;
            music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));
            FlxG.sound.list.add(music);
        }

        background.alpha = 0;

        text = new FlxText(20,-55,0,"Song Cleared!");
        text.size = 34;
        text.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
        text.color = FlxColor.WHITE;
        text.scrollFactor.set();
        add(text);

        var score = PlayState.instance.songScore;
        if (PlayState.isStoryMode)
        {
            score = PlayState.campaignScore;
            text.text = "Week Cleared!";
        }

        var sicks = PlayState.isStoryMode ? PlayState.campaignSicks : PlayState.sicks;
        var goods = PlayState.isStoryMode ? PlayState.campaignGoods : PlayState.goods;
        var bads = PlayState.isStoryMode ? PlayState.campaignBads : PlayState.bads;
        var shits = PlayState.isStoryMode ? PlayState.campaignShits : PlayState.shits;

        comboText = new FlxText(20,-75,0,'Judgements:\nSicks - ${sicks}\nGoods - ${goods}\nBads - ${bads}\n\nCombo Breaks: ${(PlayState.isStoryMode ? PlayState.campaignMisses : PlayState.misses)}\nHighest Combo: ${PlayState.highestCombo + 1}\nScore: ${PlayState.instance.songScore}\nAccuracy: ${HelperFunctions.truncateFloat(PlayState.instance.accuracy,2)}%\n\n${Ratings.GenerateLetterRank(PlayState.instance.accuracy)}\n\n${!PlayState.loadRep ? "F1 - View replay\nF2 - Replay song" : ""}
        ');
        comboText.size = 28;
        comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
        comboText.color = FlxColor.WHITE;
        comboText.scrollFactor.set();
        add(comboText);

        contText = new FlxText(FlxG.width - 475,FlxG.height + 50,0,'Press ${KeyBinds.gamepad ? 'A' : 'ENTER'} to continue.');
        contText.size = 28;
        contText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
        contText.color = FlxColor.WHITE;
        contText.scrollFactor.set();
        add(contText);

        anotherBackground = new FlxSprite(FlxG.width - 500,45).makeGraphic(450,240,FlxColor.BLACK);
        anotherBackground.scrollFactor.set();
        anotherBackground.alpha = 0;
        add(anotherBackground);
        
        graph = new HitGraph(FlxG.width - 500,45,495,240);
        graph.alpha = 0;

        graphSprite = new OFLSprite(FlxG.width - 510,45,460,240,graph);

        graphSprite.scrollFactor.set();
        graphSprite.alpha = 0;
        
        add(graphSprite);


        var sicks = HelperFunctions.truncateFloat(PlayState.sicks / PlayState.goods,1);
        var goods = HelperFunctions.truncateFloat(PlayState.goods / PlayState.bads,1);

        if (sicks == Math.POSITIVE_INFINITY)
            sicks = 0;
        if (goods == Math.POSITIVE_INFINITY)
            goods = 0;

        var mean:Float = 0;


        for (i in 0...PlayState.rep.replay.songNotes.length)
        {
            // 0 = time
            // 1 = length
            // 2 = type
            // 3 = diff
            var obj = PlayState.rep.replay.songNotes[i];
            // judgement
            var obj2 = PlayState.rep.replay.songJudgements[i];

            var obj3 = obj[0];

            var diff = obj[3];
            var judge = obj2;
            if (diff != (166 * Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166))
                mean += diff;
            if (obj[1] != -1)
                graph.addToHistory(diff, judge, obj3);
        }

        if (sicks == Math.POSITIVE_INFINITY || sicks == Math.NaN)
            sicks = 0;
        if (goods == Math.POSITIVE_INFINITY || goods == Math.NaN)
            goods = 0;

        graph.update();

        mean = HelperFunctions.truncateFloat(mean / PlayState.rep.replay.songNotes.length,2);

        settingsText = new FlxText(20,FlxG.height + 50,0,'SF: ${PlayState.rep.replay.sf} | Ratio (SA/GA): ${Math.round(sicks)}:1 ${Math.round(goods)}:1 | Mean: ${mean}ms | Played on ${PlayState.SONG.song} ${CoolUtil.difficultyFromInt(PlayState.storyDifficulty).toUpperCase()}');
        settingsText.size = 16;
        settingsText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,2,1);
        settingsText.color = FlxColor.WHITE;
        settingsText.scrollFactor.set();
        add(settingsText);


        FlxTween.tween(background, {alpha: 0.5},0.5);
        FlxTween.tween(text, {y:20},0.5,{ease: FlxEase.expoInOut});
        FlxTween.tween(comboText, {y:145},0.5,{ease: FlxEase.expoInOut});
        FlxTween.tween(contText, {y:FlxG.height - 45},0.5,{ease: FlxEase.expoInOut});
        FlxTween.tween(settingsText, {y:FlxG.height - 35},0.5,{ease: FlxEase.expoInOut});
        FlxTween.tween(anotherBackground, {alpha: 0.6},0.5, {onUpdate: function(tween:FlxTween) {
            graph.alpha = FlxMath.lerp(0,1,tween.percent);
            graphSprite.alpha = FlxMath.lerp(0,1,tween.percent);
        }});

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}


    var frames = 0;

	override function update(elapsed:Float)
	{
        if (music != null && music.volume < 0.5)
		    music.volume += 0.01 * elapsed;

        // keybinds

        if (PlayerSettings.player1.controls.ACCEPT)
        {
            music.fadeOut(0.3);
            
            PlayState.loadRep = false;
            PlayState.rep = null;

			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
			switch (songHighscore) {
				case 'Dad-Battle': songHighscore = 'Dadbattle';
				case 'Philly-Nice': songHighscore = 'Philly';
			}

			#if !switch
			Highscore.saveScore(songHighscore, Math.round(PlayState.instance.songScore), PlayState.storyDifficulty);
			Highscore.saveCombo(songHighscore, Ratings.GenerateLetterRank(PlayState.instance.accuracy),PlayState.storyDifficulty);
			#end

            if (PlayState.isStoryMode)
            {
                FlxG.sound.playMusic(Paths.music('freakyMenu'));
                Conductor.changeBPM(102);
                FlxG.switchState(new MainMenuState());
            }
            else
                FlxG.switchState(new FreeplayState());
            PlayState.instance.clean();
        }

        if (FlxG.keys.justPressed.F1 && !PlayState.loadRep)
        {
            trace(PlayState.rep.path);
            PlayState.rep = Replay.LoadReplay(PlayState.rep.path);

            PlayState.loadRep = true;
            PlayState.isSM = PlayState.rep.replay.sm;

            var songFormat = StringTools.replace(PlayState.rep.replay.songName, " ", "-");
            switch (songFormat) {
                case 'Dad-Battle': songFormat = 'Dadbattle';
                case 'Philly-Nice': songFormat = 'Philly';
                    // Replay v1.0 support
                case 'dad-battle': songFormat = 'Dadbattle';
                case 'philly-nice': songFormat = 'Philly';
            }

			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
			switch (songHighscore) {
				case 'Dad-Battle': songHighscore = 'Dadbattle';
				case 'Philly-Nice': songHighscore = 'Philly';
			}

			#if !switch
			Highscore.saveScore(songHighscore, Math.round(PlayState.instance.songScore), PlayState.storyDifficulty);
			Highscore.saveCombo(songHighscore, Ratings.GenerateLetterRank(PlayState.instance.accuracy),PlayState.storyDifficulty);
			#end

            #if sys
            if (PlayState.rep.replay.sm)
                if (!FileSystem.exists(StringTools.replace(PlayState.rep.replay.chartPath,"converted.json","")))
                {
                    Application.current.window.alert("The SM file in this replay does not exist!","SM Replays");
                    return;
                }
            #end

            var poop = "";

            #if sys
            if (PlayState.isSM)
            {
                poop = File.getContent(PlayState.rep.replay.chartPath);
                try
                    {
                PlayState.sm = SMFile.loadFile(PlayState.pathToSm + "/" + StringTools.replace(PlayState.rep.replay.songName," ", "_") + ".sm");
                    }
                    catch(e:Exception)
                    {
                        Application.current.window.alert("Make sure that the SM file is called " + PlayState.pathToSm + "/" + StringTools.replace(PlayState.rep.replay.songName," ", "_") + ".sm!\nAs I couldn't read it.","SM Replays");
                        return;
                    }
            }
            else
                poop = Highscore.formatSong(songFormat, PlayState.rep.replay.songDiff);
            #else
            poop = Highscore.formatSong(PlayState.rep.replay.songName, PlayState.rep.replay.songDiff);
            #end

            music.fadeOut(0.3);

            if (PlayState.isSM)
                PlayState.SONG = Song.conversionChecks(Song.loadFromJsonRAW(poop));
            else
                PlayState.SONG = Song.conversionChecks(Song.loadFromJson(poop, PlayState.rep.replay.songName));
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = PlayState.rep.replay.songDiff;
            LoadingState.loadAndSwitchState(new PlayState());
            PlayState.instance.clean();
        }

        if (FlxG.keys.justPressed.F2  && !PlayState.loadRep)
        {
            PlayState.rep = null;

            PlayState.loadRep = false;

			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
			switch (songHighscore) {
				case 'Dad-Battle': songHighscore = 'Dadbattle';
				case 'Philly-Nice': songHighscore = 'Philly';
			}

			#if !switch
			Highscore.saveScore(songHighscore, Math.round(PlayState.instance.songScore), PlayState.storyDifficulty);
			Highscore.saveCombo(songHighscore, Ratings.GenerateLetterRank(PlayState.instance.accuracy),PlayState.storyDifficulty);
			#end

            var songFormat = StringTools.replace(PlayState.SONG.song, " ", "-");
            switch (songFormat) {
                case 'Dad-Battle': songFormat = 'Dadbattle';
                case 'Philly-Nice': songFormat = 'Philly';
                case 'dad-battle': songFormat = 'Dadbattle';
                case 'philly-nice': songFormat = 'Philly';
            }

            var poop:String = Highscore.formatSong(songFormat, PlayState.storyDifficulty);

            if (music != null)
                music.fadeOut(0.3);

            PlayState.SONG = Song.loadFromJson(poop, PlayState.SONG.song);
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = PlayState.storyDifficulty;
            LoadingState.loadAndSwitchState(new PlayState());
            PlayState.instance.clean();
        }

		super.update(elapsed);
		
	}
}
