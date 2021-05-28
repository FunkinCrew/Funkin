import flixel.FlxSprite;

// the thing that pops up when you hit a note

class Judgement extends FlxSprite {
    public function new(X:Float, Y:Float, Judged:String, Display:String, early:Bool) {
        super(X, Y);
        // fnf full size 
        if (FNFAssets.exists('assets/images/judgements/$Display/$Judged.png')) {
			loadGraphic('assets/images/judgements/$Display/$Judged.png');
        // fnf pixel 
        } else if (FNFAssets.exists('assets/images/judgements/$Display/$Judged-pixel.png')) {
			loadGraphic('assets/images/judgements/$Display/$Judged-pixel.png');
            setGraphicSize(Std.int(width * PlayState.daPixelZoom));
            antialiasing = false;
        } else {
            // etterna
            if (FNFAssets.exists('assets/images/judgements/$Display/judgement 1x6.png')) {
				var bitmapThingy = FNFAssets.getBitmapData('assets/images/judgements/$Display/judgement 1x6.png');
                loadGraphic(bitmapThingy, true, bitmapThingy.width, Std.int(bitmapThingy.height/6));
                setGraphicSize(0, 131);
                var judgementFrame = switch (Judged) {
                    case 'shit':
                        3;
                    case 'bad':
                        2;
                    case 'good':
                        1;
                    case "sick":
                        0;
                    case _:
                        0;
                }
                animation.add('judgement', [judgementFrame]);
                animation.play('judgement');
			}
            // timing based etterna
			else if (FNFAssets.exists('assets/images/judgements/$Display/judgement 2x6.png')) {
				var bitmapThingy = FNFAssets.getBitmapData('assets/images/judgements/$Display/judgement 2x6.png');
				loadGraphic(bitmapThingy, true, Std.int(bitmapThingy.width/2), Std.int(bitmapThingy.height / 6));
				setGraphicSize(0, 131);
				var judgementFrame = 0;
                if (early) {
                    judgementFrame = switch (Judged) {
                        case 'shit':
                            6;
                        case 'sick':
                            0;
                        case 'good':
                            2;
                        case 'bad':
                            4;
                        case _:
                            0;
                    }
                } else {
					judgementFrame = switch (Judged)
					{
						case 'shit':
							7;
						case 'sick':
							1;
						case 'good':
							3;
						case 'bad':
							5;
						case _:
							0;
					}
                }
				animation.add('judgement', [judgementFrame]);
				animation.play('judgement');
            }
        }
    }
}