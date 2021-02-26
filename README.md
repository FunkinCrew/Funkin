# Friday Night Funkin Discord RPC

This is a fork that adds Discord RPC (custom status) to Funkin'. 

## Before you use
Please note that due to the way Discord's system works, apps that have not been approved are on a whitelist. 
If you want to try this out, please dm me on Discord at Jak_#0768 and I will add you to the whitelist when I can.

## Building
This won't build on html5, because I put pre-compiler tags to stop it from doing so. This should mean it only builds on desktop, but it will work on Android and stuff, so if that's what you're going for you should probably change the tags.

This uses a haxelib library called linc_discord-rpc which you should be able to download with:
```haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc```
This library has a dependency for hxcpp, which should be downloaded automatically.
