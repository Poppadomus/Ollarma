/*
    ollama_talk_fnc_makeTalkative

    Adds a "Talk" action to ANY man (civilian, friendly, enemy, independent).

    Params:
        0: OBJECT - the unit
        1: STRING - (optional) custom persona, e.g. "a grumpy old shopkeeper". "" = automatic
*/

params [
    ["_unit", objNull, [objNull]],
    ["_persona", "", [""]]
];

if (isNull _unit || {!(_unit isKindOf "CAManBase")} || {isPlayer _unit}) exitWith {};
if (_unit getVariable ["ollama_talk_added", false]) exitWith {};
_unit setVariable ["ollama_talk_added", true];
if (_persona != "") then { _unit setVariable ["ollama_persona", _persona] };

_unit addAction [
    "<t color='#8fd18f'>Talk</t>",
    {
        params ["_target", "_caller"];
        [_target, _caller] spawn ollama_talk_fnc_talk;
    },
    nil,
    1.5,
    false,
    true,
    "",
    "alive _target && {_target != _this}",
    5
];
