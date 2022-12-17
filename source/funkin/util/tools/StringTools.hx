package funkin.util.tools;

/**
 * A static extension which provides utility functions for Strings.
 */
class StringTools
{
	/**
	 * Converts a string to title case. For example, "hello world" becomes "Hello World".
     * 
	 * @param value The string to convert.
	 * @return The converted string.
	 */
	public static function toTitleCase(value:String):String
	{
        var words:Array<String> = value.split(" ");
        var result:String = "";
        for (i in 0...words.length)
        {
            var word:String = words[i];
            result += word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
            if (i < words.length - 1)
            {
                result += " ";
            }
        }
        return result;
	}

    /**
     * Converts a string to lower kebab case. For example, "Hello World" becomes "hello-world".
     * 
     * @param value The string to convert.
     * @return The converted string.
     */
    public static function toLowerKebabCase(value:String):String {
        return value.toLowerCase().replace(' ', "-");
    }

    /**
     * Converts a string to upper kebab case, aka screaming kebab case. For example, "Hello World" becomes "HELLO-WORLD".
     * 
     * @param value The string to convert.
     * @return The converted string.
     */
    public static function toUpperKebabCase(value:String):String {
        return value.toUpperCase().replace(' ', "-");
    }

    /**
     * Parses the string data as JSON and returns the resulting object.
     * 
     * @return The parsed object.
     */
    public static function parseJSON(value:String):Dynamic
    {
        return SerializerUtil.fromJSON(value);
    }
}
