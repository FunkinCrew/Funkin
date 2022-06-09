package optionsmenu;

import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import Controls.Control;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.text.FlxText;

class KeybindsState extends MusicBeatState{
    var option:FlxText;
    var background:FlxSprite;
    var camFollow:FlxSprite;

    var detailText:FlxText;

    var curSelected:Int = 0;

    var optionsArray = ['LEFT ${FlxG.save.data.left}', 'DOWN ${FlxG.save.data.down}', 'UP ${FlxG.save.data.up}'
    , 'RIGHT ${FlxG.save.data.right}'];
    var optionGroup = new FlxTypedGroup<FlxText>();

    var startListening:Bool = false;
    var selectedKey:String = '';

    override function create(){
        super.create();
        
        background = new FlxSprite(0, 0, Paths.image('menuBGBlue'));
		background.scrollFactor.x = 0;
		background.scrollFactor.y = 0;
		background.updateHitbox();
		background.screenCenter();
		background.antialiasing = true;
		add(background);

        addOptions();

        detailText = new FlxText(0, 0, FlxG.width, '');
        detailText.setFormat("PhantomMuff 1.5", 32, FlxColor.WHITE, "center");
        detailText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 4, 1);
        detailText.antialiasing = true;
        detailText.screenCenter(X);
        detailText.y = detailText.height;
        detailText.scrollFactor.x = 0;
        detailText.scrollFactor.y = 0;
        add(detailText);

        camFollow = new FlxSprite(0, 0).makeGraphic(Std.int(optionGroup.members[0].width), Std.int(optionGroup.members[0].height), 0xAAFF0000);
        FlxG.camera.follow(camFollow, null, 0.06);
    }

    function addOptions(){
        var optionYstarting = (FlxG.height * 0.5) -32;

        if (optionGroup.members.length > 0){
           for (option in optionGroup.members){
                optionGroup.remove(option);
            }
        }

        for (option in 0...optionsArray.length){
            var option = new FlxText(0, 0, FlxG.width, optionsArray[option]);
            option.setFormat("PhantomMuff 1.5", 32, FlxColor.WHITE, "center");
            option.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 4, 1);
            option.antialiasing = true;
            option.y = optionYstarting;
            optionGroup.add(option);

            optionYstarting += 32;
        }

        add(optionGroup);
        optionAlpha();
    }

    function optionAlpha(){
        if (curSelected == -1 || curSelected >= optionGroup.length) {
			return;
		}
		else{
			for (text in 0...optionGroup.members.length) {
				if (text == curSelected && optionGroup.members[text] != null) {
					optionGroup.members[text].alpha = 1;
				}
	
				if (text != curSelected && optionGroup.members[text] != null) {
					optionGroup.members[text].alpha = 0.6;
				}
			}
		}
    }

    public override function update(elapsed){
        super.update(elapsed);

        optionsArray = ['LEFT ${FlxG.save.data.left}', 'DOWN ${FlxG.save.data.down}', 'UP ${FlxG.save.data.up}'
        , 'RIGHT ${FlxG.save.data.right}'];

        camFollow.screenCenter();
		if (optionGroup.members[curSelected] != null) {
			camFollow.y = optionGroup.members[curSelected].y - camFollow.height / 2;
		}

        if (controls.UP_P && curSelected > 0 && !startListening) {
            curSelected--;
            optionAlpha();
        }
        if (controls.DOWN_P && curSelected < optionGroup.length - 1 && !startListening) {
            curSelected++;
            optionAlpha();
        }
        if (controls.ACCEPT && !startListening){
            startListening = true;
            
            switch(curSelected){
                case 0:
                    selectedKey = 'left';
                case 1:
                    selectedKey = 'down';
                case 2:
                    selectedKey = 'up';
                case 3:
                    selectedKey = 'right';
            }
        }
        if (controls.BACK && !startListening){
            FlxG.switchState(new OptionsMenu());
        }

        if (startListening)
            detailText.text = 'Press a key to bind';

        if (startListening && FlxG.keys.justPressed.ANY && !controls.ACCEPT){
            if (selectedKey == 'left'){
                controls.unbindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.left), FlxKey.LEFT]);

                FlxG.save.data.left = FlxG.keys.getIsDown()[0].ID.toString();
                trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown());

                controls.bindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.left), FlxKey.LEFT]);

                selectedKey = "";
                //Delayed so it doesn't move the Arrow
                new FlxTimer().start(0.1, function(tmr:FlxTimer)
                    {
                        detailText.text = "";
                        startListening = false;
                        addOptions();
                });
            }
            if (selectedKey == 'down'){
                controls.unbindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.down), FlxKey.DOWN]);

                FlxG.save.data.down = FlxG.keys.getIsDown()[0].ID.toString();
                trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown());

                controls.bindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.down), FlxKey.DOWN]);

                selectedKey = "";
                //Delayed so it doesn't move the Arrow
                new FlxTimer().start(0.1, function(tmr:FlxTimer)
                    {
                        detailText.text = "";
                        startListening = false;
                        addOptions();
                });
            }
            if (selectedKey == 'up'){
                controls.unbindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.up), FlxKey.UP]);

                FlxG.save.data.up = FlxG.keys.getIsDown()[0].ID.toString();
                trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown());

                controls.bindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.up), FlxKey.UP]);

                selectedKey = "";
                //Delayed so it doesn't move the Arrow
                new FlxTimer().start(0.1, function(tmr:FlxTimer)
                    {
                        detailText.text = "";
                        startListening = false;
                        addOptions();
                });
            }
            if (selectedKey == 'right'){
                controls.unbindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.right), FlxKey.RIGHT]);

                FlxG.save.data.right = FlxG.keys.getIsDown()[0].ID.toString();
                trace(FlxG.keys.getIsDown()[0].ID.toString() + " " + FlxG.keys.getIsDown());

                controls.bindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.right), FlxKey.RIGHT]);

                selectedKey = "";
                //Delayed so it doesn't move the Arrow
                new FlxTimer().start(0.1, function(tmr:FlxTimer)
                    {
                        detailText.text = "";
                        startListening = false;
                        addOptions();
                });
            }

        }
    }
}