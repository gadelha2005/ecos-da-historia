shader_type canvas_item;
// [I7] Filtro de foto antiga para a fase 1904: sépia + grão animado + vinheta.
// Vai num ColorRect que cobre a tela, numa CanvasLayer acima do mundo e abaixo da UI.
// Lê o que já foi desenhado (o mundo) pela textura de tela e recolore.

uniform sampler2D tela : hint_screen_texture, filter_nearest;

// 0.0 = cores originais, 1.0 = sépia total
uniform float intensidade : hint_range(0.0, 1.0) = 0.85;
// força do grão (ruído de filme)
uniform float grao : hint_range(0.0, 0.5) = 0.08;
// trocas de padrão do grão por segundo (baixo = grão "parado", alto = cintilante)
uniform float velocidade_grao : hint_range(1.0, 60.0) = 12.0;
// escurecimento das bordas
uniform float vinheta : hint_range(0.0, 1.0) = 0.45;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 cor = texture(tela, SCREEN_UV).rgb;

	// sépia: matriz clássica de conversão
	vec3 sepia = vec3(
		dot(cor, vec3(0.393, 0.769, 0.189)),
		dot(cor, vec3(0.349, 0.686, 0.168)),
		dot(cor, vec3(0.272, 0.534, 0.131))
	);
	cor = mix(cor, min(sepia, vec3(1.0)), intensidade);

	// grão: muda em passos discretos no tempo, para não "ferver" a cada frame
	float passo = floor(TIME * velocidade_grao);
	vec2 pixel = floor(FRAGCOORD.xy / 2.0);
	cor += (ruido(pixel + passo) - 0.5) * grao;

	// vinheta: escurece suavemente a partir do centro
	float d = distance(SCREEN_UV, vec2(0.5));
	cor *= 1.0 - smoothstep(0.35, 0.85, d) * vinheta;

	COLOR = vec4(clamp(cor, 0.0, 1.0), 1.0);
}
