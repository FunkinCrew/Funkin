package;

import lime.utils.Assets;
import haxe.Json;

typedef ArtStyle = {
    name:String,
    notes:String,
    library:String,
    antialiasing:Bool,
    popUpScore:PUS,
    comboNums:CN,
    scalings:Array<String>,
    offsets:Array<String>
}

typedef PUS = {
    sick:String,
    good:String,
    bad:String,
    shit:String
}

typedef CN = {
    zero:String,
    one:String,
    two:String,
    three:String,
    four:String,
    five:String,
    six:String,
    seven:String,
    eight:String,
    nine:String,
}

class Style {
    public static var lstyle:ArtStyle;

    public static function loadStyle(style:String) {
        var actualStyle:String = style != null ? style : 'normal'; // debug shit
        lstyle = Json.parse(Assets.getText(Paths.artStyle(actualStyle, 'artstyles')));
    }
}