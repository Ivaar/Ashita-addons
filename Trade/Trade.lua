require 'common'
require 'packet'
target = require('ffxi.target');

_addon.name = 'Trade';
_addon.version = '1.0.0.0';
_addon.author = 'Ivaar';
    
whitelist = {
    'Name',
    };

function table.tostring(t, form)
    if #t >= 1 then
        str = ' '
        for x = 1,#t do
            str = str..string.format(form,t[x]);
        end
        str = string.upper(str)..string.format('  size: [%d]',#t);
        return str;
        --return string.upper(str),string.format('  size: [%d]',#t);
    end
    return nil;
end;
    
function find_entity_name(name)
    if name ~= nil then
        for x = 0, 2048 do
            local ent = GetEntity(x);
            if (ent ~= nil and string.lower(ent.Name) == string.lower(name)) then
                return ent;
            end
        end
    end
    return nil;
end

ashita.register_event('incoming_packet', function(id, size, packet)
    if (id == 0x021) then
        local newpacket = packet:totable();
        local trader_id = newpacket[0x08+1]+newpacket[0x09+1]*256;
        local trader_name = GetEntity(trader_id).Name;
        if (table.hasvalue(whitelist,trader_name) == true) then
            local trade_accept = struct.pack("bbxxxxxxxxxx", 0x33, 0x06):totable();
            --AddOutgoingPacket(trade_accept, 0x33, #trade_accept);
        end
    elseif (id == 0x022) then
        local newpacket = packet:totable();
        local trader_id = newpacket[0x0C+1]+newpacket[0x0D+1]*256;
        local trader_name = GetEntity(trader_id).Name;
        if (table.hasvalue(whitelist,trader_name) == true) then
            if (trade_count ~= nil and newpacket[0x08+1] == 0x02) then
                local trade_confirm = struct.pack("bbxxbxxxhxx", 0x33, 0x06, 0x02, trade_count):totable();
            --AddOutgoingPacket(trade_confirm, 0x33, #trade_confirm);
            elseif (newpacket[0x04+1] ~= 0x02) then 
                trade_count = 0;
            end
        end
    elseif (id == 0x023) then
        local newpacket = packet:totable();
        trade_count = newpacket[0x08+1]+newpacket[0x09+1]*256;
    end
    return false;
end);
    
ashita.register_event('command', function(cmd, nType)
    local args = cmd:GetArgs();
    if (args[1] ~= '/trade') then
        return false;
    end

    local targ = (args[2] == nil and AshitaCore:GetDataManager():GetTarget():GetTargetEntity()) or (find_entity_name(args[2]));
    if (targ ~= nil and targ.SpawnFlags == 1 and math.sqrt(targ.Distance) <= 6) then-- and table.hasvalue(whitelist,targ.Name) == true
        local trade_offer = struct.pack("bbxxihxx", 0x32, 0x06, targ.ServerID, targ.TargetID):totable();
        
        print(string.format('%s Index:%d ID:%d',targ.Name,targ.TargetID,targ.ServerID));
        print(string.format('modified packet %s',table.tostring(trade_offer,' %.2x')));
        --AddOutgoingPacket(trade_offer, 0x32, #trade_offer);
    end
    return true;
end);
