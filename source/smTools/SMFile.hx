#if sys
package smTools;

import sys.io.File;

class SMFile
{
    public static function loadFile(path):SMFile
    {
        return new SMFile(File.getContent(path).split('\n'));
    }
    
    private var _fileData:Array<String>;

    public var _readTime:Float = 0;

    public var header:SMHeader;
    public var measures:Array<SMMeasure>;

    public function new(data:Array<String>)
    {
        _fileData = data;

        // Gather header data
        var headerData = "";
        var inc = 0;
        while(!StringTools.contains(data[inc + 1],"//"))
        {
            headerData += data[inc] + "\n";
            inc++;
            // trace(data[inc]);
        }

        header = new SMHeader(headerData.split('\n'));

        // check if this is a valid file, it should be a dance double file.
        inc += 3; // skip three lines down
        if (!StringTools.contains(data[inc],"dance-double:"))
            return;
        trace('this is dance double');

        inc += 4; // skip 5 down to where da notes @
        trace(data[inc]);

        measures = [];

        while(data[inc + 1] != ";")
        {
            var measure = "";
            while(data[inc + 1] != ",")
            {
                inc++;
                var line = data[inc];
                measure += line + "\n";
            }
            measures.push(new SMMeasure(measure.split('\n')));
        }
        trace(measures.length + " Measures");
    }
}
#end