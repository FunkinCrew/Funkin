package;

import flixel.addons.api.FlxGameJolt;
import flixel.addons.ui.FlxUIButton;
import flixel.FlxG;
import flixel.addons.ui.FlxUIInputText;
import flixel.text.FlxText;
import flixel.FlxSubState;

class LoginSubState extends FlxSubState {

    var usrnameenter:FlxUIInputText;
    var passenter:FlxUIInputText;

    var loginBtn:FlxUIButton;
    var nrnBtn:FlxUIButton;

    var showCursor:Bool = true;

    public override function create() {
        FlxG.mouse.visible = true;

        trace('opened login screen lol');
        var title = new FlxText(0, 20, 0, "Login with a Gamejolt account", 32);
        title.alignment = CENTER;
        title.screenCenter(X);
        add(title);

        usrnameenter = new FlxUIInputText(0, 0, Std.int(FlxG.width / 2), "USERNAME GOES HERE", 16);
        usrnameenter.screenCenter();
        usrnameenter.y -= 20;
        add(usrnameenter);

        passenter = new FlxUIInputText(0, 0, Std.int(FlxG.width / 2), "GAME TOKEN GOES HERE", 16);
        passenter.screenCenter();
        passenter.y += 20;
        add(passenter);

        loginBtn = new FlxUIButton(0, passenter.y + 30, "Authenticate", () -> {
            trace('authenticate i think');
            FlxGameJolt.authUser(usrnameenter.text, passenter.text);
            trace('authenticated: ${FlxGameJolt.username}');
            FlxG.mouse.visible = false;
            close();
        });
        loginBtn.screenCenter(X);
        add(loginBtn);

        nrnBtn = new FlxUIButton(0, loginBtn.y + 30, "Not right now", () -> {
            FlxG.mouse.visible = false;
            close();
        });
        nrnBtn.screenCenter(X);
        add(nrnBtn);

        var confusedBtn = new FlxUIButton(0, nrnBtn.y + 30, "What is my Game Token?", () -> {
            FlxG.openURL("https://gamejolt.com/help/tokens");
        });
        confusedBtn.screenCenter(X);
        add(confusedBtn);


        super.create();
    }

    public override function update(elapsed:Float) {
        super.update(elapsed);

        if (showCursor) {
            FlxG.mouse.visible = true;
        } else {
            FlxG.mouse.visible = false;
        }
    }
}