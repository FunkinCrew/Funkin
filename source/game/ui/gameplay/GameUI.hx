package game.ui.gameplay;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;

import game.state.PlayState;
import game.state.menus.options.PreferencesMenu;

using StringTools;

/*
    Class For The Games UI.

    Yet another Forever Engine Moment

    - Zyflx
*/

class GameUI extends FlxTypedGroup<FlxBasic>
{
    var scoreTxt:FlxText;
    var watermark:FlxText;

    var healthBarBG:FlxSprite;
    
    var healthBar:FlxBar;

    var iconP1:HealthIcon;
    var iconP2:HealthIcon;

    var Song = PlayState.SONG.song;

    // var health = PlayState.health;

    // Accuracy Shit
    var notesHit:Float = 0.0;
    var notesPlayed:Int = 0;
    var accuracy:Float;
    var rankStr:String = 'N/A';

    var rankArray:Array<Dynamic> =  [
        [100, 'SS'],
        [95, 'S'],
        [90, 'A'],
        [85, 'B'],
        [80, 'C'],
        [75, 'D'],
        [70, 'E'],
        [65, 'F']
    ];

    public var ratingMap:Map<String, Float> = [
        'sick' => 1,
        'good' => 0.67,
        'bad' => 0.34,
        'shit' => 0
    ];

    public function new()
    {
        super();

        healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		if (PreferencesMenu.getPref('downscroll')) healthBarBG.y = FlxG.height * 0.1;

        healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), PlayState,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		add(healthBar);

        iconP1 = new HealthIcon(PlayState.SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(PlayState.SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

        scoreTxt = new FlxText(0, healthBarBG.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
        scoreTxt.borderSize = 1.2;
		add(scoreTxt);

        updateScoreTxt();

        var songName = Song.replace('-', " ");
        var diffName = CoolUtil.difficultyString();
        watermark = new FlxText(0, (PreferencesMenu.getPref('downscroll') ? FlxG.height - 40 : 10), 0, '', 30);
        watermark.setFormat(Paths.font('vcr.ttf'), 30, FlxColor.WHITE);
        watermark.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.4);
        watermark.text = '~ $songName - ($diffName) ~';
        watermark.screenCenter(X);
        add(watermark);
    }

    override public function update(elapsed:Float)
    {
        // healthBar.percent = health;

        if (FlxG.keys.justPressed.NINE) iconP1.swapOldIcon();

        iconP1.scale.set(FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 11), 0, 1)), FlxMath.lerp(1, iconP1.scale.y, CoolUtil.boundTo(1 - (elapsed * 11), 0, 1)));
        iconP2.scale.set(FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 11), 0, 1)), FlxMath.lerp(1, iconP2.scale.y, CoolUtil.boundTo(1 - (elapsed * 11), 0, 1)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 1 : 0);
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : 0);

        super.update(elapsed);
    }

    public function updateScoreTxt()
    {
        var acc:Float = Math.floor(accuracy * 10000) / 100;
        updateRank(acc);
    
         scoreTxt.text = 'Score: ' + PlayState.songScore + ' - Misses: ' + PlayState.songMisses +
         ' - Accuracy: [$acc% | $rankStr]';
    }

    // Accuracy Shit Part 2
    public function updateAcc(rating:Float, ?isMiss:Bool = false)
    {
        if (!isMiss) notesHit += rating;
        notesPlayed++;
        accuracy = Math.min(1, Math.max(0, notesHit / notesPlayed));
        updateScoreTxt();
    }

    function updateRank(accuracy:Float)
    {
        for (i in 0...rankArray.length)
        {
            if (rankArray[i][0] <= accuracy)
            {
                rankStr = rankArray[i][1];
                break;
            }
        }
    }

    public function iconBeat()
    {
        iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();
    }
}