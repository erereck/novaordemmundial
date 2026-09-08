# Nova Ordem Mundial — Modo Aluno

Protótipo de launcher escolar em **AutoHotkey v2** com configuração remota e painel local.

## Teste rápido

1. Instale o AutoHotkey v2 no PC.
2. Baixe este repositório em **Code → Download ZIP** e extraia.
3. No PC do professor, abra `server/INICIAR_SERVIDOR.bat`.
4. Abra `http://127.0.0.1:8765/admin` para o painel.
5. Execute `ModoAluno.ahk`.

### Senhas de teste

- Sair do Modo Aluno: `1234`
- FNAF: `4321`

## Testar em 3 PCs

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
- Tux Paint
- Poki
- TypingLand
- PowerPoint
- Canva
- Aba Jogos
- Geometry Dash
- diep.io
- Muito, Muito Minimalista
- FNAF Web com senha
- Futbobo (`https://futbobo.top`)
- botão remoto de prova

Alguns caminhos de executáveis e URLs ainda são placeholders de protótipo.

> Isto é um kiosk leve para crianças pequenas, não segurança real do Windows. `Ctrl+Alt+Delete` não pode ser bloqueado normalmente pelo AHK.
