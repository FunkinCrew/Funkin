package modding;

#if windows
import webm.WebmIoFile;
import webm.WebmIo;
import webm.WebmPlayer;
import flixel.FlxG;
import webm.WebmEvent;
#end

class VideoHandler
{
    #if windows
    public static var video:WebmPlayer;
    public static var io:WebmIo;

    public var stopped:Bool = false;
	public var restarted:Bool = false;
	public var played:Bool = false;
	public var ended:Bool = false;
	public var paused:Bool = false;
    public var initialized:Bool = false;

    private var video_Path:String = "";

    public function new(){}

    public function makePlayer(?new_Video_Path:String)
    {
        if(new_Video_Path != null)
            video_Path = Sys.getCwd() + new_Video_Path;

        io = new WebmIoFile(Sys.getCwd() + video_Path);

        video = new WebmPlayer();
        video.fuck(io, false);

        video.addEventListener(WebmEvent.PLAY, function(e) {
			onPlay();
		});

		video.addEventListener(WebmEvent.COMPLETE, function(e) {
			onEnd();
		});

		video.addEventListener(WebmEvent.STOP, function(e) {
			onStop();
		});

		video.addEventListener(WebmEvent.RESTART, function(e) {
			onRestart();
		});

		video.visible = false;
    }

    public function updatePlayer():Void
    {
        io = new WebmIoFile(video_Path);
        video.fuck(io, false);
    }

    public function onStop():Void
    {
        stopped = true;
    }
    
    public function onRestart():Void
    {
        restarted = true;
    }
    
    public function onPlay():Void
    {
        played = true;
    }
    
    public function onEnd():Void
    {
        trace("IT ENDED!");
        ended = true;
    }

    public function play():Void
    {
        if (initialized)
        {
            video.play();
        }
    }
    
    public function stop():Void
    {
        if (initialized)
        {
            video.stop();
        }
    }
    
    public function restart():Void
    {
        if (initialized)
        {
            video.restart();
        }
    }

    public function pause():Void
    {
        video.changePlaying(false);
        paused = true;
    }
    
    public function resume():Void
    {
        video.changePlaying(true);
        paused = false;
    }
    
    public function update(elapsed:Float)
    {
        video.x = 0;
        video.y = 0;
        video.width = FlxG.width;
        video.height = FlxG.height;
    }
    #end
}