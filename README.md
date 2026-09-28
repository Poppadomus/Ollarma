# Ollarma

**Talk to AI-powered NPCs in Arma 3 using local Ollama models.**

Ollarma is a bridge between **Arma 3** and [Ollama](https://ollama.com/), allowing you to chat with in-game AI characters using open-source language models running locally on your own PC.

Each NPC keeps its own short conversation history, so characters can remember what you said previously. NPC replies are generated locally through Ollama rather than a cloud AI service.

## Features

- Chat with Arma 3 NPCs using a local Ollama model.
- Use the **Talk** interaction on nearby NPCs.
- Type directly into Arma's chat while standing near an NPC.
- The NPC you are looking at is preferred; otherwise the nearest NPC within 5 metres responds.
- Each NPC has its own conversation memory.
- NPC prompts take the current game situation into account, including faction, equipment, location, time of day and combat state.
- Replies appear as floating text above the NPC.
- Requests are handled asynchronously so the game does not freeze while Ollama generates a response.
- Supports custom NPC personas through the SQF functions.
- Everything can run locally on your machine.

## Requirements

- Arma 3
- Windows
- [Ollama](https://ollama.com/)
- An Ollama-compatible model
- BattlEye disabled while using the included DLL
- A mission hosted locally as a multiplayer mission

> **Important:** Ollarma uses an external DLL loaded by Arma 3. BattlEye must be disabled. Use this only in environments where you are permitted to run unsupported extensions.

## Installing Ollama

1. Download and install Ollama from [ollama.com](https://ollama.com/).
2. Open **Command Prompt** or **PowerShell**.
3. Download a model. For example:

```powershell
ollama pull llama3.2
```

4. Ollama normally exposes its local API at `127.0.0.1:11434`.

Ollarma currently uses `llama3.2` and `127.0.0.1:11434` as its defaults. The SQF interface also allows another model or Ollama host/port to be supplied.

## Installing Ollarma

Download or clone this repository.

### 1. Install the DLL

Copy:

```
CopyToArmaEXEdirectory/ollama_bridge_x64.dll
```

to your **Arma 3 game directory**, alongside the Arma 3 executable.

If Windows has blocked the DLL, open its **Properties** and unblock it before starting Arma 3.

### 2. Install the mission files

Copy everything inside:

```
CopyToYourMissionFolder/
```

into your Arma 3 mission folder.

The included files provide:

- `description.ext` — registers the Ollarma functions.
- `init.sqf` — makes NPCs talkative and installs the chat listener.
- `ollama_talk/` — the SQF functions used to communicate with Ollama.

### 3. Start the mission correctly

The mission needs to be hosted as a **local multiplayer mission**.

The typed-chat feature depends on Arma's multiplayer chat system, so the chat interaction is not available in a normal single-player mission.

## Using Ollarma

### Talk action

Walk up to an NPC and use the **Talk** action.

The NPC will generate a response based on its identity, faction, equipment, surroundings and the current situation.

### Direct chat

Stand within approximately **5 metres** of an NPC and type a message using Arma's chat.

Ollarma will choose the NPC you are looking at when possible. If you are not looking at a nearby NPC, it uses the nearest suitable NPC.

For example:

```
Hello, what are you doing here?
```

The NPC's response is displayed above their head.

## Conversation memory

Each NPC maintains its own conversation history.

This means talking to one NPC does not give another NPC the same conversation. The current implementation keeps the most recent exchanges for each character so conversations can continue naturally without sending an unlimited amount of history to the model.

## Custom personas

The underlying SQF function supports assigning a custom persona to an NPC.

For example:

```sqf
[npc1, "a grumpy old shopkeeper who distrusts soldiers"] call ollama_talk_fnc_makeTalkative;
```

The NPC will then use that persona when generating dialogue.

NPCs are automatically made talkative by `init.sqf`, so custom personas are only needed when you want to override the automatically generated identity.

## Available functions

| Function | Purpose |
|---|---|
| `ollama_talk_fnc_ask` | Sends a prompt to the local Ollama model and waits for the result. |
| `ollama_talk_fnc_talk` | Generates dialogue for an NPC and maintains that NPC's conversation history. |
| `ollama_talk_fnc_makeTalkative` | Adds the Talk action to an NPC and optionally assigns a persona. |
| `ollama_talk_fnc_enableChat` | Enables typed chat interaction with nearby NPCs. |

The lower-level Ollama bridge is exposed to SQF through the `ollama_bridge` extension.

## Troubleshooting

### "No reply" or DLL did not load

Check that:

1. `ollama_bridge_x64.dll` is in the Arma 3 game directory.
2. BattlEye is disabled.
3. Windows has not blocked the DLL. Check the DLL's **Properties** and use **Unblock** if it is available.
4. Arma 3 and the DLL are running on a supported 64-bit Windows installation.

### Ollama errors or timeouts

Check that Ollama is installed and running, then test that your model is available:

```powershell
ollama list
```

If `llama3.2` is missing:

```powershell
ollama pull llama3.2
```

Ollarma waits for Ollama to return a response and reports errors in Arma's system chat.

### Chat does not trigger an NPC

Make sure:

- You are within approximately 5 metres of a non-player character.
- You are running the mission as a locally hosted multiplayer mission.
- The Ollarma mission files are installed correctly.
- `description.ext` includes `ollama_talk\\CfgFunctions.hpp`.

### The NPC does not have a Talk action

Make sure the mission's `init.sqf` is being executed and that the NPC is not a player-controlled unit.

## Project structure

```
Ollarma/
├── CopyToArmaEXEdirectory/
│   └── ollama_bridge_x64.dll
├── CopyToYourMissionFolder/
│   ├── description.ext
│   ├── init.sqf
│   └── ollama_talk/
│       ├── CfgFunctions.hpp
│       ├── fn_ask.sqf
│       ├── fn_enableChat.sqf
│       ├── fn_makeTalkative.sqf
│       └── fn_talk.sqf
└── LICENSE
```

## Why Ollarma?

Modern AI tools have made it possible to interact with characters through natural language, but that capability is not limited to cloud-hosted models.

Ollarma provides a way for **open-source/local language models to interface with Arma 3**, giving mission makers and players the ability to experiment with conversational NPCs while keeping model inference on their own machine.

## License

Ollarma is released under the **MIT License**. See [LICENSE](LICENSE) for the full license text.

## Disclaimer

Ollarma is an unofficial community project and is not affiliated with or endorsed by Bohemia Interactive or Ollama.

The included DLL is an external Arma 3 extension. Disable BattlEye only where appropriate and at your own risk.
