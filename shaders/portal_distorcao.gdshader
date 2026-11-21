shader_type canvas_item;
// [K2] Distorção radial do portal ativo: o anel gira e ondula (seno + TIME).
// Vai no Sprite2D do portal. Com intensidade 0 o portal fica parado (trancado).

uniform float intensidade : hint_range(0.0, 1.0) = 1.0;  // 0 = parado, 1 = efeito completo
uniform float giro = 1.6;            // voltas do redemoinho (radianos por segundo)
uniform float torcao = 2.4;          // quanto o centro gira mais que a borda
uniform float onda_forca = 0.035;    // amplitude da ondulação radial
uniform float onda_freq = 18.0;      // anéis de ondulação
uniform float onda_vel = 6.0;        // velocidade da ondulação
uniform float brilho : hint_range(0.0, 2.0) = 1.0;
// braços em espiral desenhados pelo shader (deixam o giro visível no anel provisório;
// use 0 quando a arte do portal do E3 entrar)
uniform float bracos_forca : hint_range(0.0, 1.0) = 0.45;
uniform float bracos = 3.0;

void fragment() {
	vec2 c = UV - vec2(0.5);
	float r = length(c);
	float a = atan(c.y, c.x);
	float i = intensidade;
	a += i * (TIME * giro + (0.5 - r) * torcao);
	r += i * sin(r * onda_freq - TIME * onda_vel) * onda_forca;
	vec2 uv = vec2(0.5) + vec2(cos(a), sin(a)) * r;
	vec4 cor = texture(TEXTURE, uv);
	float espiral = 0.5 + 0.5 * sin(bracos * a + r * 22.0);
	cor.rgb *= mix(1.0, 0.55 + 0.75 * espiral, bracos_forca);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		cor.a = 0.0;
	}
	COLOR = vec4(cor.rgb * COLOR.rgb * brilho, cor.a * COLOR.a);
}
