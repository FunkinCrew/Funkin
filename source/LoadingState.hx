import flixel.FlxState;
import flixel.FlxG;
// lol
// doesn't actually load anything except fixing menus
class LoadingState {
    public static function loadAndSwitchState(target:FlxState, ?allowDjkf:Bool) {
        // allow null. By default if it is playstate enable djfk else disable
        if (allowDjkf == null) {
            if ((target is PlayState)) {
                allowDjkf = true;
            } else {
                allowDjkf = false;
            }
        }
		PlayerSettings.player1.controls.setKeyboardScheme(Solo(allowDjkf && OptionsHandler.options.DJFKKeys));
        FlxG.switchState(target);
    }
}