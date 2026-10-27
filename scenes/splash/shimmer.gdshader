shader_type canvas_item;

uniform float shimmer_speed : hint_range(0.1, 5.0) = 1.0;
uniform float shimmer_width : hint_range(0.01, 1.0) = 0.1;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float t = mod(TIME * shimmer_speed, 1.0 + shimmer_width * 2.0) - shimmer_width;
    float shimmer = smoothstep(t - shimmer_width, t, UV.x) - smoothstep(t, t + shimmer_width, UV.x);
    COLOR = tex + vec4(shimmer * 0.5, shimmer * 0.5, shimmer * 0.2, 0.0) * tex.a;
}
