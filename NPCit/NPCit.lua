require 'common';
require 'packet';
require 'timer';

_addon.name = 'NPCit';
_addon.version = '1.0.0.0';
_addon.author = 'Ivaar';

sales_que = {};

function table.find(t, val)
    for k, v in pairs(t) do
        if v == val then return k; end
    end
    return nil;
end;

function hasflag(n, flag)
    return bit.band(n, flag) == flag;
end;

function itemName(id)
   return AshitaCore:GetResourceManager():GetItemByID(tonumber(id)).Name;
end;

function find_item(item_id)
    local items = AshitaCore:GetDataManager():GetInventory();
    for i = 1,items:GetInventoryMax(0) do
        local item = items:GetInventoryItem(0, i);
        if item ~= nil and item.Id == item_id and item.Flag == 0 then
            return item.Index,item.Count;
        end
    end
    return nil;
end;

function check_que(item)
    local ind = table.find(sales_que, item);
    if ind ~= nil then
        table.remove(sales_que, ind);
    end
    if sales_que[1] ~= nil then
        return sell_npc_item(sales_que[1]);
    else
        print('Selling Finished');
        return false;
    end
end;

function check_item(name)
    local item = AshitaCore:GetResourceManager():GetItemByName(name);
    if item == nil then
        actions=nil,print(string.format('Error: %s not a valid item name.',name)); 
        return check_que(); 
    end

    if hasflag(item.Flags, ItemFlags['NoSale']) then
        actions=nil;
        print(string.format('Error: Cannot sell %s to npc vendors',item.Name));
        return check_que(item.ItemID);
    end

    table.insert(sales_que, item.ItemID);
    if actions == nil then 
        actions = true;
        return sell_npc_item(item.ItemID);
    end

    return false;
end;

function sell_npc_item(item)
    if appraised == nil then 
        actions = nil;
        return false;
    end
    
    local index,count = find_item(item);
    if index == nil then 
        actions = nil;
        if appraised[item] == nil then 
            print(string.format('Error: %s not found in inventory.',itemName(item))); 
        end
        return check_que(item);
    end
    
    if appraised[item] == nil then 
        count = 1; 
    end
    
    local appraisal = struct.pack("bbxx bxxx hbx", 0x084, 0x06, count, item, index):totable();
    AddOutgoingPacket(npcSale, 0x84, #npcSale);
    
    if appraised[item] == nil then 
        appraised[item] = true;
        return sell_loop(item);
    end
    
    local confirm = struct.pack("bbxxbxxx", 0x085, 0x04, 0x01):totable();
    AddOutgoingPacket(confirm, 0x85, #confirm);
    return sell_loop(item);
end;

function sell_loop(item)
    timer.Once((1+math.random()), sell_npc_item, item);
end;

ashita.register_event('incoming_packet', function(id, size, packet)
    if (id == 0x3C) then
        appraised = {};
        return false;
    end
    __events_incoming_packet(id, size, packet);
    return false;
end);

ashita.register_event('outgoing_packet', function(id, size, packet)
    __events_outgoing_packet(id, size, packet);
    return false;
end);

ashita.register_event('command', function(cmd, nType)
    local args = cmd:GetArgs();
    if (string.lower(args[1]) ~= '/npcit') then 
        return false;
    end
    
    if args[2] == nil then
        return true;
    end
    
    if args[2] ~= nil then
        check_item(table.concat(args,' ',2));
    elseif appraised ~= nil then
        check_que()
    end
    return true;
end)

function reset()
    appraised = nil;
end;

ashita.register_event('zone_change', reset)
ashita.register_event('logout', reset)
