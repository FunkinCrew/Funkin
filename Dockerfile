# Use haxe on debian

FROM haxe:4.1-buster

ENV LANG en_US.UTF-8 
ENV DEBIAN_FRONTEND noninteractive

# Surprisingly, we only need git for this build
RUN apt update && apt install git -y

# Install haxe dependencies
RUN haxelib install lime \ 
    && haxelib install flixel \ 
    && haxelib install flixel-addons \ 
    && haxelib install flixel-ui \
    && haxelib install hscript \
    && haxelib install newgrounds \
    && haxelib install openfl

RUN haxelib git polymod https://github.com/larsiusprime/polymod.git \
    && haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc.git

# Copy the APIStuff file so the game can work properly
COPY APIStuff.hx source

# Generate the built game for linux
CMD [ "haxelib", "run", "lime", "test", "linux" ]
