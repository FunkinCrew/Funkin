# Code Style Guide

Code style is enforced using Visual Studio Code extensions.

## .hx
Formatting is handled by the `nadako.vshaxe` extension, which includes Haxe Formatter.
Haxe Formatter automatically resolves issues such as indentation style and line breaks, and can be configured in `hxformat.json`.

Code Quality is handled by the `vshaxe.haxe-checkstyle` extension, which includes Haxe Checkstyle.

### Haxe Checkstyle Notes
* Checks can be escalated to display as different severities in the Problems window.
  * Checks can be disabled by setting the severity to `IGNORE`.
* `IndentationCharacter` checks what is used to indent, `Indentation` checks how deep the indentation is.
* `CommentedOutCode` check is in place because old code should be retrieved via Git history.
* TODO items: Enable these one-by-one and fix them to improve the overall code quality.
  - Re-configure `MethodLength`
  - Re-configure `CyclomaticComplexity`
  - Re-enable `MagicNumber`
  - Re-configure `NestedControlFlow`
  - Re-configure `NestedIfDepth`
  - Figure out something for `Trace`
  - Fix bug and enable `DocCommentStyle`

## .json
Formatting is handled by the `esbenp.prettier-vscode` extension, which includes Prettier.
Prettier automatically handles formatting of JSON files, and can be configured in `.prettierrc.js`.

### Prettier Notes
* Prettier will automatically attempt to place expressions on a single line if they fit, but will keep them multi-line if they are manually made multi-line.
  * This means that long single-line objects are automatically expanded, and short multi-line objects aren't automatically collapsed.
  * You may want to use regex replacement to manually remove the first newline in short multi-line objects to convince Prettier to collapse them.
