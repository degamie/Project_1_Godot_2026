shader_type spatial
render_mode unshaded, depth_test_disabled, cull_disabled;

// Depth and Screen Buffers
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// Color Absorption Parameters
uniform vec4 shallow_color : source_color = vec4(0.04, 0.28, 0.38, 1.0);
uniform vec4 deep_color : source_color = vec4(0.005, 0.04, 0.09, 1.0);
uniform float depth_fade_distance : hint_range(5.0, 150.0) = 45.0;

// Screen Refraction / Water Churn
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.008;
uniform float distortion_speed : hint_range(0.1, 5.0) = 1.2;

// Caustics
uniform sampler2D caustics_texture : hint_default_white, repeat_enable;
uniform float caustics_speed : hint_range(0.05, 2.0) = 0.35;
uniform float caustics_scale : hint_range(0.1, 20.0) = 2.5;
uniform float caustics_intensity : hint_range(0.0, 5.0) = 1.6;
uniform float caustics_depth_cutoff : hint_range(2.0, 80.0) = 25.0;

// Reconstruct 3D world position from depth buffer
vec3 get_world_pos(vec2 uv, mat4 inv_view, mat4 inv_proj) {
	float depth = texture(depth_texture, uv).x;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_proj * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec4 world = inv_view * vec4(view.xyz, 1.0);
	return world.xyz;
}

void vertex() {
	// Fill full clip space directly in front of camera
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// 1. Procedural Screen Distortion / Wiggle
	vec2 screen_uv = SCREEN_UV;
	float time = TIME * distortion_speed;
	vec2 wave_offset = vec2(
		sin(screen_uv.y * 18.0 + time) * cos(screen_uv.x * 12.0 + time * 0.5),
		cos(screen_uv.x * 18.0 + time) * sin(screen_uv.y * 12.0 + time * 0.5)
	) * distortion_strength;

	vec2 distorted_uv = screen_uv + wave_offset;

	// 2. Sample Scene & Calculate Distance
	vec3 scene_color = texture(screen_texture, distorted_uv).rgb;
	vec3 world_pos = get_world_pos(distorted_uv, INV_VIEW_MATRIX, INV_PROJECTION_MATRIX);
	float dist = length(world_pos - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);

	// 3. World-Projected Animated Caustics
	vec2 caustic_uv1 = (world_pos.xz * (1.0 / caustics_scale)) + vec2(TIME * caustics_speed * 0.7, TIME * caustics_speed * 0.4);
	vec2 caustic_uv2 = (world_pos.xz * (-1.0 / caustics_scale * 1.2)) + vec2(-TIME * caustics_speed * 0.5, TIME * caustics_speed * 0.6);

	float c1 = texture(caustics_texture, caustic_uv1).r;
	float c2 = texture(caustics_texture, caustic_uv2).r;
	float caustics = min(c1, c2);
	caustics = pow(caustics, 2.2) * caustics_intensity;

	// Fade caustics with depth (light absorbs as you go deeper)
	float caustic_fade = clamp(1.0 - (abs(world_pos.y) / caustics_depth_cutoff), 0.0, 1.0);
	scene_color += vec3(caustics * caustic_fade);

	// 4. Exponential Water Depth Absorption
	float depth_factor = clamp(dist / depth_fade_distance, 0.0, 1.0);
	depth_factor = pow(depth_factor, 1.4); // Realistic nonlinear roll-off

	vec3 water_tint = mix(shallow_color.rgb, deep_color.rgb, depth_factor);
	vec3 final_color = mix(scene_color, water_tint, depth_factor);

	ALBEDO = final_color;
}
