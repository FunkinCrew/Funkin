# Troubleshooting Common Issues

- Weird macro error with a very tall call stack: Restart Visual Studio Code
- `Get Thread Context Failed`: Turn off other expensive applications while building
- `Type not found: T1`: This is thrown by `json2object`, make sure the data type of `@:default` is correct.
  - NOTE: `flixel.util.typeLimit.OneOfTwo` isn't supported.
