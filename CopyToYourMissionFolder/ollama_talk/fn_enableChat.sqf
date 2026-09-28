/*
    ollama_talk_fnc_enableChat

    Lets you talk by TYPING in the chat. Whatever you type, the man you are
    looking at (or otherwise the nearest one) within 5 m replies to it.
    Call once from init.sqf.
*/

if (!isNil "ollama_talk_chatId") exitWith {};

ollama_talk_chatId = addMissionEventHandler ["HandleChatMessage", {
    params ["_channel", "_owner", "_from", "_text", "_person", "_name", "_strID", "_forced", ["_isPlayerMessage", true]];

    // only real messages typed by the player (ignore system chat, radio lines, other people)
    if (_channel == 16) exitWith { false };
    if !(_isPlayerMessage in [true, 1]) exitWith { false };
    if !((_person isEqualTo player) || {_from isEqualTo name player}) exitWith { false };
    if (_text == "") exitWith { false };

    // who is in earshot (5 m)?
    private _near = (player nearEntities ["CAManBase", 5]) select { alive _x && {_x != player} };
    if (count _near == 0) exitWith { false };

    // prefer the man you are looking at, otherwise the nearest one
    private _target = cursorTarget;
    if !(_target in _near) then {
        _near = _near apply { [_x distance player, _x] };
        _near sort true;
        _target = (_near select 0) select 1;
    };

    [_target, player, "", _text] spawn ollama_talk_fnc_talk;

    false   // do not block the message from showing in chat
}];
