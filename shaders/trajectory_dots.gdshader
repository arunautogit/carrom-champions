shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform vec4 dot_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float speed : hint_range(0.0, 10.0) = 3.0;
uniform float dot_density : hint_range(1.0, 50.0) = 15.0;
uniform float dot_size : hint_range(0.1, 0.5) = 0.35;

void fragment() {
    // Scroll along length (UV.y or UV.x depending on strip mesh orientation)
    float moving_uv = UV.x * dot_density - TIME * speed;
    float dot_dist = distance(fract(vec2(moving_uv, UV.y)), vec2(0.5, 0.5));
    
    // Smooth circle shape for each dot
    float circle = 1.0 - smoothstep(dot_size - 0.05, dot_size + 0.05, dot_dist);
    
    // Fade out towards the end of the trajectory
    float length_fade = 1.0 - smoothstep(0.7, 1.0, UV.x);
    
    ALBEDO = dot_color.rgb;
    ALPHA = circle * dot_color.a * length_fade;
}
