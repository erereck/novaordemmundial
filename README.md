# Nova Ordem Mundial — Modo Aluno

Launcher escolar em **AutoHotkey v2** com configuração remota, painel local, perfil Chrome separado, bloqueio web e atualização automática.

## Teste rápido

1. Instale o AutoHotkey v2 no PC.
2. Baixe este repositório em **Code → Download ZIP** e extraia.
3. Abra `ABRIR_MODO_ALUNO.bat`.
4. No PC do professor, se quiser usar o painel remoto, abra `server/INICIAR_SERVIDOR.bat`.
5. Abra `http://127.0.0.1:8765/admin` para o painel.

### Senhas de teste

- Sair do Modo Aluno: `1234`
- Conteúdo restrito / FNAF: `4321`

## Atalhos do professor

- `Ctrl + Alt + Shift + F12` — encerrar o Modo Aluno com senha.
- `Ctrl + Alt + Shift + U` — abrir o Chrome escolar para instalar/configurar uBlock.
- `Ctrl + Alt + Shift + Q` — **fechar tudo que estiver aberto fora do Modo Aluno** e voltar para o launcher.
- `F1` — voltar para a página inicial do launcher.
- `Alt + Tab` — liberado a partir da v5.

## Comportamento da v5

- Tudo que o launcher abre tenta iniciar e permanecer **maximizado**.
- Janelas abertas pelo Modo Aluno ficam **Always On Top**, enquanto o launcher permanece atrás.
- O launcher continua aberto em segundo plano para recuperação.
- O atalho de fechamento total encerra a sessão do aluno sem fechar o Modo Aluno.
- `roblox.com` é bloqueado no Chrome escolar.
- Qualquer URL contendo simultaneamente as palavras `love` e `calculator` também é bloqueada.

## Atualização automática

A partir da **v5**, `version.txt` controla a versão do programa.

O launcher consulta periodicamente:

`https://raw.githubusercontent.com/erereck/novaordemmundial/main/version.txt`

Se existir uma versão mais nova e não houver jogo/site/programa aberto, ele:

1. encerra o launcher;
2. baixa o ZIP mais recente do `main`;
3. atualiza os arquivos;
4. preserva `settings.ini`, `cache/`, `.git/` e arquivos locais extras;
5. reabre o Modo Aluno.

O perfil Chrome escolar fica fora da pasta do projeto, em `%LOCALAPPDATA%\NovaOrdemMundial\ChromeProfile`, então extensões e dados desse perfil sobrevivem às atualizações.

**Importante:** PCs que ainda estão na v4 precisam receber a v5 manualmente uma última vez. Depois disso, as próximas versões podem ser puxadas automaticamente.

## Testar em vários PCs

No PC que vai servir de painel, rode `ipconfig` e copie o IPv4, por exemplo `192.168.0.25`.

Nos PCs dos alunos, altere `settings.ini`:

```ini
[Sync]
RemoteConfigURL=http://192.168.0.25:8765/config.ini
SyncSeconds=10
```

Troque `192.168.0.25` pelo IP real do PC do professor.

O painel permite ligar/desligar a aba de jogos e fazer surgir um botão especial de prova. O launcher consulta a configuração periodicamente e mantém cache local.

## Já incluído

- Google
- Tux Paint em fullscreen nativo
- Poki
- Typing Land (Microsoft Store)
- PowerPoint
- Canva
- Geometry Dash
- diep.io
- MMM
- FNAF Web com senha
- Futbobo
- CAO The Game
- Krunker
- Stopots
- Gartic
- Gartic Phone
- botão remoto de prova

> Isto é um kiosk leve para crianças pequenas, não segurança real do Windows. `Ctrl+Alt+Delete` continua pertencendo ao Secure Desktop do Windows e não é bloqueado normalmente pelo AHK.
