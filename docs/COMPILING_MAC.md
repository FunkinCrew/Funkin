# Mac Compiling Guide + Considerations

There's a few extra considerations when compiling FNF for Mac that *we* have to handle when creating a wider release.
- [Creating a Universal Binary](#creating-a-universal-binary)
- Code-signing
- Notarizing

## Creating a Universal Binary

Run the `art/macos-universal.sh` script, which automatically compiles release versions of both arm64 and x86 of Funkin. You can also see there for reference of how it's done.
