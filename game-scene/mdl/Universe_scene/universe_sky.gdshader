shader_type sky;

// Mahavatar Narsimha inspired cosmos: indigo void, saffron/gold divine light,
// vermilion heat at the nebula edges, and slow-drifting starfield.

uniform vec3 deep_indigo : source_color = vec3(0.02, 0.0, 0.12);
uniform vec3 divine_blue : source_color = vec3(0.06, 0.0, 0.55);
uniform vec3 saffron_gold : source_color = vec3(1.0, 0.62, 0.15);
uniform vec3 vermilion : source_color = vec3(0.85, 0.12, 0.05);
uniform float nebula_strength = 0.9;
uniform float star_threshold = 0.985;
uniform float star_brightness = 2.0;
uniform float swirl_speed = 0.02;
uniform float drift_speed = 0.012;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float value_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
		f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * value_noise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);

	// Slow swirl around the vertical axis so the cosmos feels alive.
	float ang = TIME * swirl_speed;
	float c = cos(ang);
	float s = sin(ang);
	vec3 d = vec3(c * dir.x - s * dir.z, dir.y, s * dir.x + c * dir.z);

	// Zenith indigo fading into a warm saffron horizon glow.
	float up = clamp(dir.y, 0.0, 1.0);
	vec3 col = mix(saffron_gold * 0.30, deep_indigo, pow(up, 0.6));

	// Two-layer nebula drifting in opposite directions.
	float n1 = fbm(d * 2.5 + vec3(0.0, TIME * drift_speed, 0.0));
	float n2 = fbm(d * 5.0 - vec3(TIME * drift_speed * 1.3));
	vec3 nebula = mix(divine_blue, vermilion, smoothstep(0.45, 0.8, n2));
	nebula = mix(nebula, saffron_gold, smoothstep(0.55, 0.95, n1) * 0.6);
	col += nebula * smoothstep(0.35, 0.9, n1) * nebula_strength * 0.6;

	// Twinkling stars on a jittered grid.
	vec3 cell = floor(d * 220.0);
	float h = hash(cell);
	float star = step(star_threshold, h);
	float twinkle = 0.6 + 0.4 * sin(TIME * 3.0 + h * 40.0);
	col += vec3(1.0, 0.9, 0.7) * star * twinkle * star_brightness;

	COLOR = col;
}
