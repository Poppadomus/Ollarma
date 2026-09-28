[] spawn { 
    if (!hasInterface) exitWith {}; 
    waitUntil {!isNull player}; 
 
    { [_x] call ollama_talk_fnc_makeTalkative } forEach allUnits; 
 
    addMissionEventHandler ["EntityCreated", { 
        params ["_entity"]; 
        if (_entity isKindOf "CAManBase") then { [_entity] call ollama_talk_fnc_makeTalkative }; 
    }]; 
 
    [] call ollama_talk_fnc_enableChat; 
};

if (isNil "ollama_talk_fnc_talk") exitWith { systemChat "ERROR: ollama_talk_fnc_talk is missing - fn_talk.sqf / CfgFunctions.hpp not loaded" }; 
 
if (!isNil "ollama_talk_chatId") then { removeMissionEventHandler ["HandleChatMessage", ollama_talk_chatId] }; 
 
ollama_talk_chatId = addMissionEventHandler ["HandleChatMessage", { 
    params ["_channel", "_owner", "_from", "_text", "_person", "_name"]; 
    if (_channel == 16) exitWith { false }; 
 
    systemChat format ["[chat debug] channel=%1 from=%2 person=%3 text=%4", _channel, _from, _person, _text]; 
 
    private _mine = (_person isEqualTo player) || {_from isEqualTo name player} || {_name isEqualTo name player}; 
    if (!_mine) exitWith { systemChat "[chat debug] ignored: not sent by you"; false }; 
 
    private _near = (player nearEntities ["CAManBase", 5]) select { alive _x && {_x != player} }; 
    systemChat format ["[chat debug] men within 5m: %1", count _near]; 
    if (count _near == 0) exitWith { false }; 
 
    private _target = cursorTarget; 
    if !(_target in _near) then { 
        _near = _near apply { [_x distance player, _x] }; 
        _near sort true; 
        _target = (_near select 0) select 1; 
    }; 
 
    systemChat format ["[chat debug] replying: %1", name _target]; 
    [_target, player, "", _text] spawn ollama_talk_fnc_talk; 
    false 
}]; 
 
systemChat "Chat listener installed - stand within 5m of a man and type something";
