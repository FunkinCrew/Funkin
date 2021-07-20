import lime.media.AudioSource;
import lime.media.AudioBuffer;
import openfl.media.Sound;
import openfl.display.Graphics;
import openfl.display.Sprite;

class OFLWaveform extends Sprite
{
    public var musicLength = 0;
    public var _x = 0;
    public var _y = 0;

    public var _sound:String;

    function new(x,y,musicLength, data:String)
    {    
        super();
        
        _x = x;
        _y = y;
        _sound = data;
        this.musicLength = musicLength;
    }

    public function drawWaveform()
    {
        var gfx:Graphics = graphics;
        gfx.clear();
    }
}