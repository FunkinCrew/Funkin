#if sys
package smTools;

class SMMeasure
{
    public var notes:Array<SMNote>;

    private var _measure:Array<String>;

    public function new(measureData:Array<String>)
    {
        _measure = measureData;
        notes = [];

        // 0 = no note
        // 1 = normal note
        // 2 = head of sustain
        // 3 = tail of sustain

        for(i in measureData)
        {
            for (ii in 0...i.length)
            {
                notes.push(new SMNote(i.split('')[ii],ii));
            }
        }
    }
}
#end