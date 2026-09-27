#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;
uniform sampler2D shadowtex0;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;


const vec3 skyLightColor = vec3(0.1, 0.1, 0.25);
const vec3 blockLightColor = vec3(0.2, 0.2, 0.1);
const vec3 sunlightColor = vec3(.5);
const vec3 moonlightColor = vec3(0.1);
const vec3 ambientLightColor = vec3(0.25);
uniform vec3 shadowLightPosition;
uniform int worldTime;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 albedo;

void main() {

    

	albedo = texture(gtexture, texcoord) * glcolor;
    vec3 skyLight = skyLightColor * lmcoord.x;

    bool isNight = (worldTime > 13000 && worldTime < 22000);
    vec3 blockLight = blockLightColor * lmcoord.y;
    vec3 sunDirection = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
    // SHADOWS
    vec3 NDCPos = vec3(texcoord.xy, 0.0) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;

    shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    shadowClipPos.z -= 0.001;
    shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
    
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
    
    float shadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
    vec3 sunlight = vec3(1.0) * max(dot(normal, sunDirection), 0.0) * shadow;
    if(isNight){
        sunlight *= moonlightColor;
    } else {
        sunlight *= sunlightColor;
    }

    vec3 ambientLight = ambientLightColor;
    albedo.rgb *= skyLight + blockLight + sunlight + ambientLight;
	if (albedo.a < alphaTestRef) {
		discard;
	}
}
