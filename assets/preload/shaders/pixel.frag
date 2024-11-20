#pragma header

const int pixelization = 8;
const bool smoothen = false;

vec4 flixel_texture2DExtra(sampler2D bitmap, vec2 coord) {
    if(true)
    {
        if (!smoothen)
        {
            vec2 newColor = vec2(
                coord[0] - mod(coord[0], pixelization / openfl_TextureSize[0]),
                coord[1] - mod(coord[1], pixelization / openfl_TextureSize[1])
            );
            return texture2D(bitmap, newColor);
        }
        else
        {
            vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
            for(int i = 0 ; i < pixelization ; i++)
            {
                vec2 newColor = vec2(
                    coord[0] + (i / openfl_TextureSize[0]) - mod(coord[0], pixelization / openfl_TextureSize[0]),
                    coord[1] + (i / openfl_TextureSize[1]) - mod(coord[1], pixelization / openfl_TextureSize[1])
                );
                vec4 toAdd = texture2D(bitmap, newColor);
                color[0] += toAdd[0];
                color[1] += toAdd[1];
                color[2] += toAdd[2];
                color[3] += toAdd[3];
            }

            color[0] /= pixelization;
            color[1] /= pixelization;
            color[2] /= pixelization;
            color[3] /= pixelization;
            return color;
        }
    }
    return texture2D(bitmap, coord);
}

void main() {
    gl_FragColor = flixel_texture2DExtra(bitmap, openfl_TextureCoordv);
    // gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
}