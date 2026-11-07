shader_type canvas_item;

// 0.0 = sem efeito, 1.0 = bordas bem escuras
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float borda = smoothstep(0.3, 0.75, d);
	COLOR = vec4(0.0, 0.0, 0.0, borda * intensidade);
}