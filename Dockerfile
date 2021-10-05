# Use haxe on debian

FROM haxe:4.1-buster

ENV LANG C.UTF-8
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

# Copy all files to the working directory
# TODO: make this smaller
COPY APIStuff.hx source
COPY project.xml CHANGELOG.md ./
COPY assets ./assets
COPY example_mods ./example_mods
COPY art ./art
# Generate the built game for linux
CMD [ "haxelib", "run", "lime", "test", "linux" ]
