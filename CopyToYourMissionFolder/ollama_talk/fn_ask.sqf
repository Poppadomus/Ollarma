/*
    ollama_talk_fnc_ask

    Ask the local Ollama model for a line of dialogue. Non-blocking: the DLL
    works in the background and this script checks back every 0.2s, so the
    game does not freeze. MUST be run scheduled (spawn / execVM).

    The reply is shown as floating text above the speaker's head.
    Errors are shown in the system chat (bottom-left).

    Params:
        0: STRING - prompt
        1: OBJECT - (optional) unit the text appears above
        2: STRING - (optional) model, default "llama3.2"
        3: STRING - (optional) host:port, default "127.0.0.1:11434"

    Returns: STRING - the reply, or an "ERROR: ..." string
*/

params [
    ["_prompt", "", [""]],
    ["_speaker", objNull, [objNull]],
    ["_model", "llama3.2", [""]],
    ["_hostPort", "127.0.0.1:11434", [""]]
];

if (_prompt == "") exitWith { "ERROR: empty prompt" };

// ---- one-time setup of the floating text renderer (same idea as Draw3D + drawIcon3D) ----
if (isNil "ollama_talk_drawId") then {
    ollama_talk_bubbles = [];   // each: [unit, [lines], endTime]
    ollama_talk_drawId = addMissionEventHandler ["Draw3D", {
        private _now = diag_tickTime;
        ollama_talk_bubbles = ollama_talk_bubbles select {
            ((_x select 2) > _now) && {!isNull (_x select 0)} && {alive (_x select 0)}
        };
        {
            _x params ["_unit", "_lines", "_end"];
            private _dist = player distance _unit;
            if (_dist < 60) then {
                private _alpha = linearConversion [_end - 1, _end, _now, 1, 0, true];
                private _size = linearConversion [0, 60, _dist, 0.045, 0.03, true];
                private _base = _unit modelToWorldVisual ((_unit selectionPosition "head") vectorAdd [0, 0, 0.5]);
                private _n = count _lines;
                for "_i" from 0 to (_n - 1) do {
                    private _pos = _base vectorAdd [0, 0, (_n - 1 - _i) * 0.16];
                    drawIcon3D ["", [1, 1, 1, _alpha], _pos, 0, 0, 0, _lines select _i, 2, _size, "PuristaMedium", "center"];
                };
            };
        } forEach ollama_talk_bubbles;
    }];
};

private _unwrap = { if (_this isEqualType []) then { _this select 0 } else { _this } };

// 1) start the request, get a ticket id back instantly
private _id = ("ollama_bridge" callExtension ["ask", [_prompt, _model, _hostPort]]) call _unwrap;

private _result = "";
if (_id == "") then {
    _result = "ERROR: no reply - the DLL did not load (check ollama_bridge_x64.dll is in the Arma 3 game folder, BattlEye is off, and it is unblocked in file Properties)";
} else {
    if ((_id select [0,6]) == "ERROR:") then {
        _result = _id;
    } else {
        // 2) poll until ready (max ~90s)
        private _tries = 0;
        waitUntil {
            sleep 0.2;
            _tries = _tries + 1;
            _result = ("ollama_bridge" callExtension ["get", [_id]]) call _unwrap;
            (_result != "PENDING") || (_tries > 450)
        };
        if (_result == "PENDING") then { _result = "ERROR: timed out waiting for Ollama" };
    };
};

if ((_result select [0,6]) == "ERROR:") then {
    systemChat format ["[Ollama] %1", _result];
} else {
    if (!isNull _speaker && {alive _speaker}) then {
        // wrap text into short lines so it stays readable above the head
        private _clean = (_result splitString (toString [10, 13])) joinString " ";
        private _lines = [];
        private _cur = "";
        {
            if (_cur == "") then {
                _cur = _x;
            } else {
                if (count (_cur + " " + _x) <= 36) then {
                    _cur = _cur + " " + _x;
                } else {
                    _lines pushBack _cur;
                    _cur = _x;
                };
            };
        } forEach (_clean splitString " ");
        if (_cur != "") then { _lines pushBack _cur };

        private _duration = (3 + 0.07 * count _clean) min 15;

        // replace any older bubble from the same unit
        ollama_talk_bubbles = ollama_talk_bubbles select { !((_x select 0) isEqualTo _speaker) };
        ollama_talk_bubbles pushBack [_speaker, _lines, diag_tickTime + _duration];
    } else {
        systemChat _result;
    };
};

_result
