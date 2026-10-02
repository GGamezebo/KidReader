shader_type canvas_item;

// Frosted / watery blur over a photo. blur_strength 0 = clear.
// blur_scale: raise for textures drawn much smaller than their pixel size (thumbnails).

uniform float blur_strength : hint_range(0.0, 1.0) = 1.0;
uniform float frost_amount : hint_range(0.0, 1.0) = 0.55;
uniform vec4 frost_tint : source_color = vec4(0.75, 0.88, 0.95, 1.0);
uniform float blur_scale : hint_range(0.5, 20.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	float strength = blur_strength * blur_strength;
	vec2 px = TEXTURE_PIXEL_SIZE * mix(0.5, 10.0, strength) * blur_scale;

	vec4 c = texture(TEXTURE, uv) * 0.20;
	c += texture(TEXTURE, uv + vec2(px.x, 0.0)) * 0.10;
	c += texture(TEXTURE, uv - vec2(px.x, 0.0)) * 0.10;
	c += texture(TEXTURE, uv + vec2(0.0, px.y)) * 0.10;
	c += texture(TEXTURE, uv - vec2(0.0, px.y)) * 0.10;
	c += texture(TEXTURE, uv + px) * 0.08;
	c += texture(TEXTURE, uv - px) * 0.08;
	c += texture(TEXTURE, uv + vec2(px.x, -px.y)) * 0.08;
	c += texture(TEXTURE, uv + vec2(-px.x, px.y)) * 0.08;
	c += texture(TEXTURE, uv + px * 2.0) * 0.04;
	c += texture(TEXTURE, uv - px * 2.0) * 0.04;

	float n = fract(sin(dot(uv * 80.0, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 frosted = mix(c.rgb, frost_tint.rgb, frost_amount * strength * 0.65);
	frosted += (n - 0.5) * 0.08 * strength;
	COLOR = vec4(frosted, c.a);
}
