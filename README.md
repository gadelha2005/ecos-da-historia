\# Ecos da História



Aventura 2D top-down feita na Godot, com episódios da história do Brasil ambientados na Unifor. Projeto da disciplina de Computação Gráfica (Unifor).



\## Versão da engine



\- \*\*Godot 4.7.2\*\* (versão oficial do grupo, não trocar sem combinar)

\- Renderer: \*\*Compatibility\*\*

\- Linguagem: \*\*GDScript\*\*



\## Como abrir o projeto



1\. Clone o repositório: `git clone https://github.com/gadelha2005/ecos-da-historia.git`

2\. Abra a Godot 4.7.2 e clique em \*\*Importar\*\*.

3\. Selecione a pasta clonada, a que contém o `project.godot`.



Não versionamos a pasta `.godot/` (cache da Godot). Ela é recriada sozinha ao abrir o projeto.



\## Regras de trabalho



\- A branch `main` é protegida: ninguém envia commit direto para ela.

\- Cada tarefa tem uma branch `feature/<id>-<nome-curto>`, por exemplo `feature/C1-player`.

\- Todo PR precisa de pelo menos \*\*1 revisão\*\* de outro integrante antes do merge.

\- Quem revisa deve abrir o projeto na própria máquina e testar a mudança.

\- Antes de editar uma cena `.tscn`, confira na tabela abaixo se ninguém está editando a mesma cena.



\## Quem está editando cada cena



| Cena | Responsável | Status |

| --- | --- | --- |

| (preencher) | | |



\## Estrutura de pastas



```

res://

&#x20; scenes/     hub/, fases/, player/, ui/, comum/

&#x20; scripts/    autoload/, player/, ui/, comum/

&#x20; assets/     sprites/, tiles/, audio/, fontes/

&#x20; shaders/

```



Convenções: arquivos em `snake\_case`, classes com `class\_name` em `PascalCase`, uma cena por arquivo.



\## Documentação do projeto



GDD, Narrativa e Storyboard ficam fora deste repositório, na pasta compartilhada do projeto.



