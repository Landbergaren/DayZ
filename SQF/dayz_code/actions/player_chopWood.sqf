
private ["_item","_result","_dis","_sfx","_num","_breaking","_countOut","_woodCutting","_findNearestTree","_objName","_counter","_isOk","_proceed","_animState","_started","_finished","_isMedic","_itemOut"];

//if (!isnil "faco_player_chopWood") exitWith { _this call faco_player_chopWood };

_item = _this;
call gear_ui_init;
closeDialog 1;
_countOut = 3;
_woodCutting = false;


if (["forest",dayz_surfaceType] call fnc_inString) then {
	_countOut = floor(random 3) + 2;
	_woodCutting = true;
	
} else {
	_findNearestTree = objNull;
	{
		_objName = _x call fn_getModelName;
		// Exit since we found a tree
		if (_objName in dayz_trees) exitWith { _findNearestTree = _x; };
	} foreach nearestObjects [getPosATL player, [], 8];
	
    _countOut = floor(random 3) + 2;
	
	if (!isNull _findNearestTree) then {
		_woodCutting = true;
	} else {
		cutText [localize "str_player_23", "PLAIN DOWN"];
	};
};


if (_woodCutting) then {
    //Remove melee magazines (BIS_fnc_invAdd fix) (add new melee ammo to array if needed)
    {player removeMagazines _x} forEach ["Hatchet_Swing","Crowbar_Swing","Machete_Swing","Fishing_Swing"];

    // Start chop tree loop
    _counter = 0;
    _isOk = true;
    _proceed = false;

    while {_isOk} do {
        //play action   
        player playActionNow "Medic";

        //setup alert and speak
        _dis=20;
        _sfx = "chopwood";
        [player,_sfx,0,false,_dis] call dayz_zombieSpeak;
        [player,_dis,true,(getPosATL player)] call player_alertZombies;
        
        // Working-Factor for chopping wood.
        ["Working",0,[100,15,10,0]] call dayz_NutritionSystem;

        r_interrupt = false;
        _animState = animationState player;
        r_doLoop = true;
        _started = false;
        _finished = false;

        while {r_doLoop} do {
            _animState = animationState player;
            _isMedic = ["medic",_animState] call fnc_inString;
            if (_isMedic) then {
                _started = true;
            };
            if (_started and !_isMedic) then {
                r_doLoop = false;
                _finished = true;
            };
            if (r_interrupt) then {
                r_doLoop = false;
            };

            sleep 0.1;
        };

        if(!_finished) exitWith {
            _isOk = false;
            _proceed = false;
        };

        if(_finished) then {                
            _breaking = false;
            if ([0.04] call fn_chance) then {
                _breaking = true;
                if ("MeleeHatchet" in weapons player) then {
                    player removeWeapon "MeleeHatchet";
                } else {
                    if ("ItemHatchet" in weapons player) then {
                        player removeWeapon "ItemHatchet";
                    } else {
                        if (dayz_onBack == "MeleeHatchet") then {
                            dayz_onBack = "";
                        };
                    };
                };
                if (!("ItemHatchetBroken" in weapons player)) then {
                    player addWeapon "ItemHatchetBroken";
                };
            };
            
            _counter = _counter + 1;
            _itemOut = "ItemLog";
			//Drop Item to ground
			_itemOut call fn_dropItem;
        };
            
        if ((_counter == _countOut) || _breaking) exitWith {
            if (_breaking) then {
                cutText [localize "str_HatchetHandleBreaks", "PLAIN DOWN"];
            } else {
                cutText [localize "str_player_24_Stoped", "PLAIN DOWN"];
            };
            _isOk = false;
            _proceed = true;
            sleep 1;
        };
        cutText [format [localize "str_player_24_progress", _counter,_countOut], "PLAIN DOWN"];
    };

    if (_proceed) then {            
        if ("" == typeOf _findNearestTree) then { 
        //remove vehicle, Need to ask server to remove.
          PVDZ_objgather_Knockdown = [_findNearestTree,player];
          publicVariableServer "PVDZ_objgather_Knockdown";
        };            
        //cutText [format["\n\nChopping down tree.], "PLAIN DOWN"];
        //cutText [localize "str_player_25", "PLAIN DOWN"];
    } else {
        cutText [localize "str_player_24_Stoped", "PLAIN DOWN"];

        r_interrupt = false;

        if (vehicle player == player) then {
            [objNull, player, rSwitchMove,""] call RE;
            player playActionNow "stop";
        };
    };
    //adding melee mags back if needed
    switch (primaryWeapon player) do {
        case "MeleeHatchet": {player addMagazine 'Hatchet_Swing';};
        case "MeleeCrowbar": {player addMagazine 'Crowbar_Swing';};
        case "MeleeMachete": {player addMagazine 'Machete_Swing';};
        case "MeleeFishingPole": {player addMagazine 'Fishing_Swing';};
    };
};
