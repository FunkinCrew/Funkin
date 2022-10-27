package funkin.noteStuff;

import funkin.noteStuff.NoteBasic.NoteType;
import funkin.play.Strumline.StrumlineStyle;

class NoteEvent extends Note
{
	public function new(strumTime:Float = 0, noteData:NoteType, ?prevNote:Note, ?sustainNote:Bool = false, ?style:StrumlineStyle = NORMAL)
	{
		super(strumTime, noteData, prevNote, sustainNote, style);
	}
}
