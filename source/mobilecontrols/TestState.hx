package mobilecontrols;

import flixel.input.mouse.FlxMouse;
import flixel.ui.FlxButton;
import mobilecontrols.MControls;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.addons.ui.FlxUIState;

import ui.FlxVirtualPad;

class TestState extends FlxUIState
{
    private var mcontrols(get, never):MControls;

	inline function get_mcontrols():MControls{
        return new MControls('player0');
    }

    var versionShit:FlxText;

    var button:FlxButton;

    var _pad:FlxVirtualPad;

    public function new(){
        //mcontrols.addVirtualPad(_pad);
        super();
    }

    override function create()
    {
        versionShit = new FlxText(0, 0, 0,"test");
        versionShit.screenCenter();
        versionShit.y = 48;
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 48, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

        button = new FlxButton(10, 10, 'show keyboard', () -> {
            FlxG.stage.window.textInputEnabled = true;
        });
        button.setGraphicSize(200);
        button.updateHitbox();

        button.label.setGraphicSize(150);
        button.updateHitbox();

        add(button);

        _pad = new FlxVirtualPad(FULL, A_B);
        //mcontrols.addVirtualPad(_pad);
		_pad.alpha = 0.75;
		this.add(_pad);

        
        super.create();
    }
    override function update(elapsed:Float)
    {
        if (true) setText();
        super.update(elapsed);
    }

    function setText() {
        versionShit.text = 
        'UP = ${bool2string(mcontrols.UP)}\n'
        
        'UP_P = ${bool2string(mcontrols.UP_P)}\n' +
        'UP_R = ${bool2string(mcontrols.UP_R)}\n' +
        'UP = ${bool2string(mcontrols.UP)}\n' +

        '\n' +

        'DOWN = ${bool2string(mcontrols.DOWN)}\n' +
        'LEFT = ${bool2string(mcontrols.LEFT)}\n' +
        'RIGHT = ${bool2string(mcontrols.RIGHT)}\n' +
        
        '\n' +

        'ACCEPT = ${bool2string(mcontrols.ACCEPT)}\n' +
        'BACK = ${bool2string(mcontrols.BACK)}\n'
        
        ;
    }

    function bool2string(bool:Bool = false) {
        if (bool) return 'true';
        return 'false';
    }
}