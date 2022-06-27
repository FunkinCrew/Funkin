package engine.io;

using StringTools;
class TextFileParser
{
    public static function parse(text:String, delimiter:String = ":"):Array<Array<String>>
    {
        var result:Array<Array<String>> = [];

        var splitText = text.trim().split("\n");
        
        for (line in splitText)
        {
            if (line.startsWith("#"))
                continue;
            
            result.push(line.split(delimiter));
        }

        return result;
    }

    public static function stringify(data:Array<Array<String>>, delimiter:String = ":"):String
    {
        var result = "";

        for (line in data)
        {
            for (entry in line)
            {
                result += entry + delimiter;
            }

            result = result.substring(0, result.length - 1);

            result += "\n";
        }

        return result;
    }
}