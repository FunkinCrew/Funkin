#pragma header




// TODO: shouldn't this be isolated?

//
// Description : Array and textureless GLSL 2D/3D/4D simplex
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20201014 (stegu)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
//

vec3 mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
	return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r) {
	return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
	const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
	const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

	// First corner
	vec3 i  = floor(v + dot(v, C.yyy) );
	vec3 x0 =   v - i + dot(i, C.xxx) ;

	// Other corners
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min( g.xyz, l.zxy );
	vec3 i2 = max( g.xyz, l.zxy );

	//   x0 = x0 - 0.0 + 0.0 * C.xxx;
	//   x1 = x0 - i1  + 1.0 * C.xxx;
	//   x2 = x0 - i2  + 2.0 * C.xxx;
	//   x3 = x0 - 1.0 + 3.0 * C.xxx;
	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
	vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

	// Permutations
	i = mod289(i);
	vec4 p = permute( permute( permute(
				i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
			+ i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
			+ i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

	// Gradients: 7x7 points over a square, mapped onto an octahedron.
	// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
	float n_ = 0.142857142857; // 1.0/7.0
	vec3  ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

	vec4 x = x_ *ns.x + ns.yyyy;
	vec4 y = y_ *ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4( x.xy, y.xy );
	vec4 b1 = vec4( x.zw, y.zw );

	//vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
	//vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

	vec3 p0 = vec3(a0.xy,h.x);
	vec3 p1 = vec3(a0.zw,h.y);
	vec3 p2 = vec3(a1.xy,h.z);
	vec3 p3 = vec3(a1.zw,h.w);

	//Normalise gradients
	vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	// Mix final noise value
	vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
									dot(p2,x2), dot(p3,x3) ) );
}










struct Light {
	vec2 position;
	vec3 color;
	float radius;
};

// prevent auto field generation
#define UNIFORM uniform

uniform float uScale;
uniform float uIntensity;
uniform float uTime;
uniform float uPuddleY;
uniform float uPuddleScaleY;
uniform sampler2D uBlurredScreen;
uniform sampler2D uMask;
uniform sampler2D uLightMap;
uniform int numLights;

uniform bool uSpriteMode;

uniform vec3 uRainColor;

const int MAX_LIGHTS = 8;
UNIFORM Light lights[MAX_LIGHTS];

float rand(vec2 a) {
	return fract(sin(dot(mod(a, vec2(1000.0)).xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float ease(float t) {
	return t * t * (3.0 - 2.0 * t);
}

float rainDist(vec2 p, float scale, float intensity) {
	// scale everything
	p *= 0.1;
	// sheer
	p.x += p.y * 0.1;
	// scroll
	p.y -= uTime * 500.0 / scale;
	// expand Y
	p.y *= 0.03;
	float ix = floor(p.x);
	// shift Y
	p.y += mod(ix, 2.0) * 0.5 + (rand(vec2(ix)) - 0.5) * 0.3;
	float iy = floor(p.y);
	vec2 index = vec2(ix, iy);
	// mod
	p -= index;
	// shift X
	p.x += (rand(index.yx) * 2.0 - 1.0) * 0.35;
	// distance
	vec2 a = abs(p - 0.5);
	float res = max(a.x * 0.8, a.y * 0.5) - 0.1;
	// decimate
	bool empty = rand(index) < mix(1.0, 0.1, intensity);
	return empty ? 1.0 : res;
}

float rippleHeight(vec2 p, vec2 pos, float age, float size, float modSize, float thickness) {
	float strength = 1.0 - exp(-(1.0 - age) * 1.0);
	float h = max(0.0, 1.0 - abs(length(mod(p - pos + modSize * 0.5, vec2(modSize)) - modSize * 0.5) - size * age) / thickness);
	h = h * h * (3.0 - 2.0 * h); // smoothstep
	return h * strength;
}

vec2 puddleDisplace(vec2 p, float intensity) {
	vec2 res = vec2(0);

	const int numRipples = 30;
	const float rippleLife = 0.8;
	const float rippleSize = 100.0;
	const float rippleMod = rippleSize * 2.0;
	for (int i = 0; i < numRipples; i++) {
		float shift = float(i) / float(numRipples);
		float rippleNumber = uTime / rippleLife + shift;
		float rippleId = floor(rippleNumber);
		rippleId = rand(vec2(rippleId, i));
		float x = rand(vec2(rippleId, rippleId + 1.0)) * rippleMod;
		float y = rand(vec2(rippleId + 2.0, rippleId + 3.0)) * rippleMod;
		vec2 pos = vec2(x, y);
		float age = fract(rippleNumber);
		float thickness = 4.0;
		float eps = 1.0;
		vec2 pScale = vec2(1, 1.0 / uPuddleScaleY);
		float hc = rippleHeight(p * pScale, pos, age, rippleSize, rippleMod, thickness);
		float hx = rippleHeight((p + vec2(eps, 0)) * pScale, pos, age, rippleSize, rippleMod, thickness);
		float hy = rippleHeight((p + vec2(0, eps)) * pScale, pos, age, rippleSize, rippleMod, thickness);
		vec2 normal = (vec2(hx, hy) - hc) / eps;
		res += normal * 20.0;
	}
	return res;
}

vec3 lightUp(vec2 p) {
	vec3 res = vec3(0);
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= numLights) {
			break;
		}
		vec2 lp = lights[i].position;
		vec3 lc = lights[i].color;
		float lr = lights[i].radius;
		float w = max(0.0, 1.0 - length(lp - p) / lr);
		res += ease(w) * lc;
	}
	return res;
}

vec2 worldToBackground(vec2 worldCoord) {
	// this should work as long as the background sprite is placed at the origin without scaling
	return worldCoord / uScreenResolution;
}

void main() {

	vec2 wpos = screenToWorld(screenCoord);
	if (uSpriteMode) wpos = screenToWorld(screenToFrame(openfl_TextureCoordv));
	vec2 origWpos = wpos;
	float intensity = uIntensity;

	vec3 add = vec3(0);
	float rainSum = 0.0;

	const int numLayers = 4;
	float scales[4];
	scales[0] = 1.0;
	scales[1] = 1.8;
	scales[2] = 2.6;
	scales[3] = 4.8;

	for (int i = 0; i < numLayers; i++) {
		float scale = scales[i];
		float r = rainDist(wpos * scale / uScale + 500.0 * float(i), scale, intensity);
		if (r < 0.0) {
			float v = (1.0 - exp(r * 5.0)) / scale * 2.0;
			wpos.x += v * 10.0 * uScale;
			wpos.y -= v * 2.0 * uScale;
			add += vec3(0.1, 0.15, 0.2) * v;
			rainSum += (1.0 - rainSum) * 0.75;
		}
	}


	//vec3 light = (texture2D(uLightMap, screenCoord).xyz + lightUp(wpos)) * intensity;

	vec3 color = sampleBitmapWorld(wpos).xyz;
	float alpha = sampleBitmapWorld(wpos).w;
	if (uSpriteMode) {
		vec2 rwpos = worldToScreen(wpos - origWpos);
		color = flixel_texture2D(bitmap, openfl_TextureCoordv + rwpos).xyz;
		alpha = flixel_texture2D(bitmap, openfl_TextureCoordv + rwpos).w;
	}

	/*
	bool isPuddle = texture2D(uMask, screenCoord).x > 0.5;
	if (isPuddle) {
		vec2 wpos2 = vec2(wpos.x, uPuddleY - (wpos.y - uPuddleY) / uPuddleScaleY);
		wpos2 += puddleDisplace(wpos / uScale, intensity) * uScale;
		vec3 reflection = texture2D(uBlurredScreen, worldToScreen(wpos2)).xyz * 0.3 + 0.3;
		float reflectionRatio = 1.0;
		color = reflection;
	}
	*/

	color += add;
	color = mix(color, uRainColor, 0.1 * rainSum);

	// vec3 fog = light * (0.5 + rainSum * 0.5);
	// color = color / (1.0 + fog) + fog;

	gl_FragColor = vec4(color, alpha);
}
