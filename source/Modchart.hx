package;

import lime.utils.Assets;

class Modchart {
    var lua = new vm.lua.Lua();
    var contents:String;

    public function new(song:String) {
        contents = Assets.getText(Paths.modchart(song));
        trace('MODCHART!!!!!!!!!!!!! ${Paths.modchart(song)}');
        lua.run(contents);
    }

    public function songStart(song:String) {
        lua.call('songStart' [song]);
    }

    public function update(elapsed:Float) {
        lua.call('update', [elapsed]);
    }

    public function beatHit(beat:Int) {
        lua.call('beatHit', [beat]);
    }

    public function stepHit(step:Int) {
        lua.call('stepHit', [step]);
    }

    public function die() {
        lua.destroy();
    }
}