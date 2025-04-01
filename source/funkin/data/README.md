# funkin.data

Data structures are parsed using `json2object`, which uses macros to generate parser classes based on anonymous structures OR classes.

Parsing errors will be returned in `parser.errors`. See `json2object.Error` for an enumeration of possible parsing errors. If an error occurred, `parser.value` will be null.

The properties of these anonymous structures can have their behavior changed with annotations:

- `@:optional`: The value is optional and will not throw a parsing error if it is not present in the JSON data.
- `@:default("test")`: If the value is optional, this value will be used instead of `null`. Replace `"test"` with a value of the property's type.
- `@:default(auto)`: If the value is an anonymous structure with `json2object` annotations, each field will be initialized to its default value.
- `@:jignored`: This value will be ignored by the parser. Their presence will not be checked in the JSON data and their values will not be parsed.
- `@:alias`: Choose the name the value will use in the JSON data to be separate from the property name. Useful if the desired name is a reserved word like `public`.
- `@:jcustomparse`: Provide a custom function for parsing from a JSON string into a value.
  - Functions must be of the signature `(hxjsonast.Json, String) -> T`, where the String is the property name and `T` is the type of the property.
  - `hxjsonast.Json` contains a `pos` and a `value`, with `value` being an enum: https://nadako.github.io/hxjsonast/hxjsonast/JsonValue.html
  - Errors thrown in this function will cause a parsing error (`CustomFunctionException`) along with a position!
  - Make sure to provide the FULLY QUALIFIED path to the custom function.
- `@:jcustomwrite`: Provide a custom function for serializing the property into a string for storage as JSON.
  - Functions must be of the signature `(T) -> String`, where `T` is the type of the property.

