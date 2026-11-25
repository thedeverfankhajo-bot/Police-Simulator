shader_type spatial;

uniform vec3 asphalt_color : source_color = vec3(0.105, 0.12, 0.135);
uniform vec2 surface_dimensions = vec2(8.0, 220.0);

float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);

	float lower_left = hash21(cell);
	float lower_right = hash21(cell + vec2(1.0, 0.0));
	float upper_left = hash21(cell + vec2(0.0, 1.0));
	float upper_right = hash21(cell + vec2(1.0, 1.0));

	return mix(
		mix(lower_left, lower_right, local.x),
		mix(upper_left, upper_right, local.x),
		local.y
	);
}

float layered_noise(vec2 point) {
	float result = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		result += value_noise(point) * amplitude;
		point = point * 2.03 + vec2(19.1, 7.7);
		amplitude *= 0.5;
	}
	return result;
}

void fragment() {
	vec2 road_space = UV * max(surface_dimensions, vec2(0.001));
	float broad_variation = layered_noise(road_space * 0.15);
	float aggregate = value_noise(road_space * 1.15);
	float grain = value_noise(road_space * 16.0);
	float wear = value_noise(road_space * 0.035);

	float albedo_variation =
		(broad_variation - 0.5) * 0.16 +
		(aggregate - 0.5) * 0.12 +
		(grain - 0.5) * 0.05;
	float worn_area = smoothstep(0.62, 0.92, wear) * 0.035;

	ALBEDO = asphalt_color * (0.90 + albedo_variation - worn_area);
	ROUGHNESS = clamp(0.88 + grain * 0.08, 0.80, 0.99);
}
