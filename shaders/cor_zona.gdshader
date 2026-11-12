shader_type canvas_item;
// [K1] Cor por zona do hub: tudo começa em cinza e cada zona ganha cor quando a
// chave da época é encaixada. Vai num ColorRect cheio numa CanvasLayer acima do mundo
// e abaixo da UI (camada 50); lê o que já foi desenhado pela textura de tela.
//   cinza     = dot(cor.rgb, vec3(0.299, 0.587, 0.114))
//   cor final = mix(vec3(cinza), cor.rgb, t)

uniform sampler2D tela : hint_screen_texture, filter_nearest;

// 4 retângulos (x, y, largura, altura) em pixels de tela, um por época (0 = 1904 ... 3 = 1982)
uniform vec4 zonas[4];
// quanto de cor cada zona tem: 0 = cinza, 1 = cor original
uniform float t_zonas[4];
// cor fora das zonas
uniform float t_geral : hint_range(0.0, 1.0) = 0.0;
// tamanho da tela em pixels (o mesmo espaço dos retângulos), enviado pelo script
uniform vec2 tamanho_tela = vec2(1920.0, 1080.0);
// largura da transição suave na borda das zonas, em pixels de tela
uniform float borda = 6.0;

void fragment() {
	vec4 cor = texture(tela, SCREEN_UV);
	vec2 p = SCREEN_UV * tamanho_tela;
	float t = t_geral;
	for (int i = 0; i < 4; i++) {
		vec4 z = zonas[i];
		if (z.z <= 0.0 || z.w <= 0.0) {
			continue;
		}
		// distância até a borda do retângulo (positiva dentro)
		vec2 dentro = min(p - z.xy, z.xy + z.zw - p);
		float peso = smoothstep(0.0, max(borda, 0.001), min(dentro.x, dentro.y));
		t = mix(t, t_zonas[i], peso);
	}
	float cinza = dot(cor.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(cinza), cor.rgb, t), 1.0);
}
