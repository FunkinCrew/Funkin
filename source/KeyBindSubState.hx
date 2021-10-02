// broken lol feel free to fix and PR

package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxSubState;

class KeyBindSubState extends FlxSubState {
    var editingBinds = false;

    var bindText:FlxText;

    public override function create() {
        super.create();

        // setting default binds lmao
        if (FlxG.save.data.d == null)
            FlxG.save.data.d = "d";
        if (FlxG.save.data.f == null)
            FlxG.save.data.f = "f";
        if (FlxG.save.data.j == null)
            FlxG.save.data.j = "j";
        if (FlxG.save.data.k == null)
            FlxG.save.data.k = "k";

        bindText = new FlxText(0, 0, 0, '${FlxG.save.data.d},${FlxG.save.data.f},${FlxG.save.data.j},${FlxG.save.data.k}\nPRESS ENTER TO EDIT!', 32);
        bindText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        bindText.antialiasing = true;
        add(bindText);
    }

    public override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ENTER && !editingBinds) {
            editingBinds = true;
            FlxG.save.data.d = null;
            FlxG.save.data.f = null;
            FlxG.save.data.j = null;
            FlxG.save.data.k = null;
            bindText.text = '_,_,_,_\nPress 4 keys!';
        }
        if (FlxG.keys.justPressed.ANY && editingBinds) {
            if (FlxG.save.data.d == null && FlxG.save.data.d != -1) {
                FlxG.save.data.d = FlxG.keys.firstPressed();
                bindText.text = '${FlxG.save.data.d},_,_,_\nPress 3 keys!';
            }

            if (FlxG.save.data.f == null && FlxG.save.data.f != -1) {
                FlxG.save.data.f = FlxG.keys.firstPressed();
                bindText.text = '${FlxG.save.data.d},${FlxG.save.data.f},_,_\nPress 2 keys!';
            }

            if (FlxG.save.data.j == null && FlxG.save.data.j != -1) {
                FlxG.save.data.j = FlxG.keys.firstPressed();
                bindText.text = '${FlxG.save.data.d},${FlxG.save.data.f},${FlxG.save.data.j},_\nPress 1 key!';
            }

            if (FlxG.save.data.k == null && FlxG.save.data.k != -1) {
                FlxG.save.data.k = FlxG.keys.firstPressed();
                bindText.text = '${FlxG.save.data.d},${FlxG.save.data.f},${FlxG.save.data.j},${FlxG.save.data.k}\nPress 0 keys!';
            }
        }
    }
}