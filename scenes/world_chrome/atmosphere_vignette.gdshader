shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 2.0) = 1.4;
uniform float vignette_softness : hint_range(0.05, 2.0) = 0.6;
uniform vec4 vignette_color : source_color = vec4(0.04, 0.05, 0.10, 1.0);
uniform float max_darkness : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * vignette_strength;
	float vignette = smoothstep(0.3, 0.3 + vignette_softness, dist);
	COLOR = vec4(vignette_color.rgb, vignette * max_darkness);
}
