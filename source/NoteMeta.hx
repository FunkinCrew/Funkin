package;

class NoteMeta
{
	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var sustainLength:Float = 0;

	public function new(strumTime:Float, noteData:Int, sustain:Float)
	{
		this.strumTime = strumTime;
		this.noteData = noteData;
		sustainLength = sustain;
	}
}
