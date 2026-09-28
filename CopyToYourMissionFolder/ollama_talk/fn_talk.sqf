/*
    ollama_talk_fnc_talk

    Makes one man say something to the player. If _said is "" he starts/greets
    with a random topic; otherwise he replies to what the player typed.
    Each man remembers the last few lines of the conversation.

    Params:
        0: OBJECT - the man who speaks
        1: OBJECT - the player
        2: STRING - (optional) custom persona ("" = auto)
        3: STRING - (optional) what the player said ("" = greeting)

    MUST be run scheduled (spawn).
*/

params [
    ["_man", objNull, [objNull]],
    ["_caller", objNull, [objNull]],
    ["_persona", "", [""]],
    ["_said", "", [""]]
];

if (isNull _man || {!alive _man}) exitWith {};
if (_man getVariable ["ollama_busy", false]) exitWith {};
_man setVariable ["ollama_busy", true];

if (_persona == "") then { _persona = _man getVariable ["ollama_persona", ""] };

// ---- who is he? ----
private _side = side group _man;
private _role = getText (configFile >> "CfgVehicles" >> typeOf _man >> "displayName");
private _who = _persona;
if (_who == "") then {
    _who = if (_side isEqualTo civilian) then {
        format ["%1, an ordinary civilian going about your day", name _man]
    } else {
        format ["%1, a %2 (%3 side)", name _man, _role, _side]
    };
};

// ---- is anything actually happening? (only if someone nearby is in combat) ----
private _tense = (behaviour _man isEqualTo "COMBAT") || {
    ({alive _x && {behaviour _x isEqualTo "COMBAT"} && {_x distance _man < 150}} count allUnits) > 0
};

private _hour = floor daytime;
private _timeOfDay = switch (true) do {
    case (_hour < 5): {"night"};
    case (_hour < 12): {"morning"};
    case (_hour < 17): {"afternoon"};
    case (_hour < 21): {"evening"};
    default {"night"};
};

private _friendly = (_side getFriend (side group _caller)) >= 0.6;
private _attitude = switch (true) do {
    case (_side isEqualTo civilian): {
        if (_tense) then { "You are nervous because there is trouble nearby." } else { "You are relaxed, calm and ordinary, neither scared nor overly friendly." }
    };
    case _friendly: { "The player is on your side; you talk like a friendly, professional comrade." };
    default { "The player is on the opposing side; you are cold, curt and suspicious, but not aggressive unless provoked." };
};

// ---- real facts he may use ----
private _facts = [];
private _pFaction = getText (configFile >> "CfgFactionClasses" >> faction _caller >> "displayName");
if (_pFaction != "") then { _facts pushBack format ["the player belongs to %1", _pFaction] };
private _pWeapon = getText (configFile >> "CfgWeapons" >> primaryWeapon _caller >> "displayName");
if (_pWeapon != "") then { _facts pushBack format ["the player is carrying a %1", _pWeapon] } else { _facts pushBack "the player has no rifle" };
if (vehicle _caller != _caller) then {
    _facts pushBack format ["the player is in a %1", getText (configFile >> "CfgVehicles" >> typeOf vehicle _caller >> "displayName")];
};
private _mWeapon = getText (configFile >> "CfgWeapons" >> primaryWeapon _man >> "displayName");
if (_mWeapon != "" && {!(_side isEqualTo civilian)}) then { _facts pushBack format ["you carry a %1", _mWeapon] };
if (damage _man > 0.3) then { _facts pushBack "you are injured" };
private _locs = nearestLocations [getPosATL _man, ["NameVillage","NameCity","NameCityCapital","NameLocal"], 1500];
private _place = if (count _locs > 0) then { text (_locs select 0) } else { "" };
if (_place != "") then { _facts pushBack format ["you are near %1", _place] };
_facts pushBack format ["the time is %1", _timeOfDay];
private _aimedAt = (cursorTarget isEqualTo _man) && {!weaponLowered _caller} && {currentWeapon _caller != ""};
if (_aimedAt) then { _facts pushBack "the player is pointing a weapon at you" };

// ---- conversation memory ----
private _hist = _man getVariable ["ollama_history", []];
private _histText = if (count _hist > 0) then { format ["Conversation so far: %1. ", _hist joinString " | "] } else { "" };

// ---- what to do this turn ----
private _task = "";
private _rules = "";
if (_said != "") then {
    _task = format ["The player says to you: %1. In ONE short, natural sentence, reply directly to what they said.", str _said];
    _rules = "Rules: stay in character and speak like a normal person; answer what was said; do NOT invent enemies, weapons, gunfire, attacks or dangers unless the player asks about them; do NOT tell the player to take cover; no stage directions, no quotation marks, do not mention being an AI.";
} else {
    private _topics = [
        format ["greet the player in a way that fits the %1", _timeOfDay],
        "ask the player who they are and where they are from",
        "ask the player what they are doing around here",
        "comment on the player's gear or weapon",
        "ask the player if they need anything",
        "ask how the player's day is going",
        "talk about your own job or what you were just doing",
        "ask the player for a small favour, like directions or a cigarette",
        "make a light, friendly joke",
        "say something curious about the player's faction"
    ];
    if (_place != "") then { _topics pushBack format ["say something short about %1, where you are", _place] };
    if !(_side isEqualTo civilian) then { _topics pushBack "mention your duties or orders in a general way" };
    private _topic = selectRandom _topics;
    if (_tense) then { _topic = "briefly acknowledge the tense situation" };
    if (_aimedAt) then { _topic = "react to the player pointing a weapon at you" };
    _task = format ["The player has just started talking to you. In ONE short, natural sentence, %1.", _topic];
    _rules = "Rules: speak like a normal person; only refer to the facts above; do NOT invent enemies, weapons, gunfire, attacks or dangers; do NOT tell the player to take cover; do not talk about the weather; no stage directions, no quotation marks, do not mention being an AI.";
};

private _prompt = format [
    "You are %1. %2 Things are %3 around you. Facts you know (use one only if it fits): %4. %5%6 %7",
    _who, _attitude, if (_tense) then {"tense"} else {"quiet and calm"}, _facts joinString "; ", _histText, _task, _rules
];

private _reply = [_prompt, _man] call ollama_talk_fnc_ask;

// remember the exchange (last 8 lines)
if !((_reply select [0,6]) == "ERROR:") then {
    _hist pushBack (if (_said != "") then { format ["Player: %1", _said] } else { "Player greets you" });
    _hist pushBack format ["You: %1", _reply];
    if (count _hist > 8) then { _hist = _hist select [count _hist - 8, 8] };
    _man setVariable ["ollama_history", _hist];
};

_man setVariable ["ollama_busy", false];
