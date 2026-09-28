if (!hasInterface) exitWith {};
waitUntil {!isNull player};

// Should print "pong" if the DLL loaded
systemChat format ["ollama_bridge ping: %1", "ollama_bridge" callExtension "ping"];

// Every man that already exists gets a "Talk" action...
{ [_x] call ollama_talk_fnc_makeTalkative } forEach allUnits;

// ...and so does every man that spawns later
addMissionEventHandler ["EntityCreated", {
    params ["_entity"];
    if (_entity isKindOf "CAManBase") then { [_entity] call ollama_talk_fnc_makeTalkative };
}];

// Typing in chat: the man you look at (or the nearest, within 5 m) replies
[] call ollama_talk_fnc_enableChat;
