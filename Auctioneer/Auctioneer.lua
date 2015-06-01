require 'common';
require 'packet';
require 'timer';

_addon.name = 'Auctioneer';
_addon.version = '1.0.0.1';
_addon.author = 'Ivaar';

default = {
    text = {size = 10,font = 'Consolas',pos = {x = 0,y = 0}},
    auction_list = {
        visibility=true,
        timer=true,
        date=true,
        price=false,
        empty=true,
        slot=true,
    };
};

zones = {};
zones.ah = {'Bastok Mines', 'Bastok Markets', 'Norg', 'Southern San d\'Oria', 'Port San d\'Oria', 'Raboa', 'Windurst Woods', 'Windurst Walls', 'Kazham', 'Lower Jueno', 'Ru\'Lude Gardens', 'Port Jueno', 'Upper Jueno', 'Aht Urhgan Whitegate', 'Al Zahbi', 'Nashmau', 'Tavnazian Safehold', 'Western Adoulin', 'Eastern Adoulin'};
zones.mh = {};

function table.find(t, val)
    for k, v in pairs(t) do
        if (v == val) then return k; end
    end
    return nil;
end;

function table.tostring(t, form)
    str = '';
    for x = 1,#t do
        str = str..string.format(form,t[x]);
    end
    return str;
end;

function hasflag(n, flag)
    return bit.band(n, flag) == flag;
end;

function itemName(id)
    return AshitaCore:GetResourceManager():GetItemByID(tonumber(id)).Name;
end;

function timef(ts)
    --return string.format('%.2d:%.2d:%.2d',ts/(60*60), ts/60%60, ts%60);
    return string.format('%d days %.2d:%.2d:%.2d',ts/(60*60*24), ts/(60*60)%24, ts/60%60, ts%60);
end;

local display_box = function()
    local outstr = '';
    for x = 0,6 do
        if (auction_box[x] ~= nil) then
            local str = '';
            if (config.auction_list.empty == true or auction_box[x].status ~= 'Empty') then
                if (config.auction_list.slot) == true then
                    str = str..string.format(' Slot:%s', x+1);
                end
                str = str..string.format(' %s',auction_box[x].status);
            end
            if (auction_box[x].status ~= 'Empty') then
                local timer = auction_box[x].status == 'On auction' and auction_box[x].timestamp+248836 or auction_box[x].timestamp;
                if (config.auction_list.timer) then
                    str = str..string.format(' %s',(auction_box[x].status == 'On auction' and os.time()-timer > 0) and 'Expired' or timef(math.abs(os.time()-timer)));
                end
                if (config.auction_list.date) then
                    str = str..string.format(' [%s]',os.date('%c', timer));
                end
                str = str..string.format(' %s ',auction_box[x].item);
                if (auction_box[x].count ~= 1) then
                    str = str..string.format('x%d ',auction_box[x].count);
                end
                if (config.auction_list.price) then
                    str = str..string.format('[%s] ',comma_value(auction_box[x].price));
                end
            end
            if (str ~= '') then 
                outstr = outstr ~= '' and outstr .. '\n' .. str or str;
            end
        end
    end
    return outstr;
end;

ashita.register_event('unload', function()
    AshitaCore:GetFontManager():DeleteFontObject('auction_list');
    settings:save(_addon.path .. 'settings/settings.json', config);
end);

ashita.register_event('load', function()
    config = settings:load(_addon.path .. 'settings/settings.json') or default;
    config = table.merge(default, config);
    auction_list = AshitaCore:GetFontManager():CreateFontObject('auction_list');
    auction_list:SetFont(config.text.font,config.text.size);
    auction_list:SetPosition(config.text.pos.x,config.text.pos.y);
    auction_list:SetVisibility(config.auction_list.visibility);
    auction_list:GetBackground():SetVisibility(true);
end);

ashita.register_event('render', function()
    if (auction_box ~= nil and config.auction_list.visibility == true) then
        auction_list:SetText(display_box());
        auction_list:SetVisibility(true);
    else
        auction_list:SetVisibility(false);
    end
end);

ashita.register_event('command', function(cmd, nType)
    local args = cmd:GetArgs();
    if (#args == 0) then return false; end
    
    args[1] = string.lower(args[1]);
    if (args[1] ~= '/ah' and args[1] ~= '/buy' and args[1] ~= '/sell' and args[1] ~= '/inbox' and args[1] ~= '/outbox' and args[1] ~= '/ibox' and args[1] ~= '/obox') then
        return false;
    end
    
    local zone = AshitaCore:GetResourceManager():GetString('areas', AshitaCore:GetDataManager():GetParty():GetPartyMemberZone(0));
    local now = os.clock();
    if (table.hasvalue(zones.ah,zone) == true and (lclock == nil or lclock < now)) then
        if (args[1] == '/sell' or args[1] == '/buy') then
            if (#args < 4) then return true; end
            if ah_proposal(string.lower(args[1]),table.concat(args,' ',2,#args-2),args[#args-1],args[#args]) == true then lclock = now+3; end
            return true;
        end
        
        if (args[1] == '/outbox' or args[1] == '/obox') then
            local obox = struct.pack("bbxxbbbbbbbbbbbbbbbb", 0x4B,0x0A,0x0D,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF):totable();
            --print(string.format('modified %s  size [%d]',table.tostring(obox, '%.2X '),#obox));
            AddIncomingPacket(obox, 0x4B, #obox);
            return true;
        end
        
        if (args[1] == '/inbox' or args[1] == '/ibox') then
            local ibox = struct.pack("bbxxbbbbbbbbbbbbbbbb", 0x4B,0x0A,0x0E,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF):totable();
            --print(string.format('modified %s  size [%d]',table.tostring(ibox, '%.2X '),#ibox));
            AddIncomingPacket(ibox, 0x4B, #ibox);
            return true;
        end
        
        if (#args == 1 or string.lower(args[2]) == 'menu') then
            lclock = now+3;
            AddIncomingPacket(struct.pack("bbbbbbbi32i21", 0x4C,0x1E,0x00,0x00,0x02,0x00,0x01,0x00,0x00):totable(), 0x4C, 60);
            return true;
        elseif (string.lower(args[2]) == 'clear') then
            lclock = now+3; 
            clear_sales();
            return true;
        end
    end
    
    if (args[1] ~= '/ah') then
        return false;
    end
    
    if (#args == 1) then
        return false;
    end
    
    args[2] = string.lower(args[2]);
    if (args[2] == 'show') then
        if (#args == 2) then
            config.auction_list.visibility = true;
        elseif config.auction_list[string.lower(args[3])] ~= nil then
            config.auction_list[string.lower(args[3])] = true
        end
    elseif (args[2] == 'hide') then
        if (#args == 2) then
            config.auction_list.visibility = false;
        elseif config.auction_list[string.lower(args[3])] ~= nil then
            config.auction_list[string.lower(args[3])] = false
        end
    end
    return true;
end);

function update_sales_status(packet)
    local slot = packet:byte(0x05+1);
    local status = packet:byte(0x14+1);
    if (auction_box ~= nil and slot ~= 7 and status ~= 0x02 and status ~= 0x04 and status ~= 0x10) then
        if (status == 0x00) then
            auction_box[slot] = {};
            auction_box[slot].status = 'Empty';
        else
            if (status == 0x03) then
                auction_box[slot].status = 'On auction';
            elseif (status == 0x0A or status == 0x0C or status == 0x15) then
                auction_box[slot].status = 'Sold';
            elseif (status == 0x0B or status == 0x0D or status == 0x16) then
                auction_box[slot].status = 'Not Sold';
            end
            auction_box[slot].item = itemName(struct.unpack('h', packet, 0x28+1));
            auction_box[slot].count = packet:byte(0x2A+1);
            auction_box[slot].price = struct.unpack('i', packet, 0x2C+1);
            auction_box[slot].timestamp = struct.unpack('i', packet, 0x38+1);
        end
    end
end;

function find_empty_slot()
    if (auction_box ~= nil) then
        for slot = 0,6 do
            if (auction_box[slot] ~= nil and auction_box[slot].status == 'Empty') then
                return slot;
            end
        end
    end
    return nil;
end;

ashita.register_event('incoming_packet', function(id, size, packet)
    if (id == 0x04C) then
        local pType = packet:byte(5);
        if (pType == 0x04) then
            local slot = find_empty_slot()
            local fee = struct.unpack('i', packet, 9)
            if (last4E ~= nil and packet:byte(7) == 0x01 and slot ~= nil and last4E ~= nil and last4E:byte(5) == 0x04 and packet:sub(13,17) == last4E:sub(13,17) and AshitaCore:GetDataManager():GetInventory():GetInventoryItem(0, 0).Count >= fee) then				
                local sell_confirm = struct.pack("bbxxbbxxbbbbbbxxbi32i11", 0x4E,0x1E,0x0B,slot,last4E:byte(9),last4E:byte(10),last4E:byte(11),last4E:byte(12),packet:byte(13),packet:byte(14),last4E:byte(17),0x00,0x00):totable();
                last4E = nil
                timer.Once(math.random(), function()
                    --print(string.format('modified %s  size [%d]',table.tostring(sell_confirm ,'%.2X '),#sell_confirm));
                    AddOutgoingPacket(sell_confirm, 0x4E, #sell_confirm);
                end);
            end
        elseif (pType == 0x0A) then
            if (packet:byte(7) == 0x01) then
                if (auction_box == nil) then auction_box = {}; end
                if (auction_box[packet:byte(6)] == nil) then auction_box[packet:byte(6)] = {}; end
                update_sales_status(packet);
            end
        elseif (pType == 0x0B or pType == 0x0C or pType == 0x0D or pType == 0x10) then
            if (packet:byte(7) == 0x01) then
                update_sales_status(packet);
            end
        elseif (pType == 0x0E) then
            if (packet:byte(7) == 0x01) then
                print('Bid Success');
            elseif (packet:byte(7) == 0xC5) then
                print('Bid Failed');
            end
        end
    elseif (id == 0x00B) then
        if (packet:byte(5) == 0x01) then
            auction_box = nil;
        end
    end
    return false;
end);

function comma_value(n) -- credit http://richard.warburton.it
    local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$');
    return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right;
end;

function find_item(item_id, item_count)
    local items = AshitaCore:GetDataManager():GetInventory();
    for ind = 1,items:GetInventoryMax(0) do
        local item = items:GetInventoryItem(0, ind);
        if (item ~= nil and item.Id == item_id and item.Flag == 0 and item.Count >= item_count) then
            return item.Index;
        end
    end
    return nil;
end;

function clear_sales()
    if (auction_box == nil) then return false; end
    for slot=0,6 do
        if (auction_box[slot] ~= nil) and (auction_box[slot].status == 'Sold' or auction_box[slot].status == 'Not Sold') then
            local isold = struct.pack("bbxxbbi32i22", 0x4E,0x1E,0x10,slot,0x00,0x00):totable();
            --print(string.format('modified %s  size [%d]',table.tostring(isold, '%.2X '),#isold));
            --AddOutgoingPacket(isold, 0x4E, #isold);
        end
    end
end;

function ah_proposal(bid, name, vol, price)
    name = ParseAutoTranslate(name, false);
    local item = AshitaCore:GetResourceManager():GetItemByName(name, 2);
    if (item == nil) then 
        print(string.format('AH Error: "%s" not a valid item name.',name));
        return false; 
    end

    if (hasflag(item.Flags, ItemFlags['NoAuction']) == true) then
        print(string.format('AH Error: %s is not purchasable via the auction house.',item.Name));
        return false;
    end

    local single;
    if (item.StackSize ~= 1) and (vol == '1' or vol == 'stack') then
        single = 0;
    elseif (vol == '0' or vol == 'single') then
        single = 1;
    else print('AH Error: Specify single or stack.'); 
        return false;
    end

    price = price:gsub('%p', '');
    if (price == nil) or
      (string.match(price,'%a') ~= nil) or
      (tonumber(price) == nil) or
      (tonumber(price) < 1) or
      (bid == '/sell' and tonumber(price) > 999999999) or
      (bid == '/buy' and tonumber(price) > AshitaCore:GetDataManager():GetInventory():GetInventoryItem(0,0).Count) then
        print('AH Error: Invalid price.');
        return false;
    end
    price = tonumber(price);

    local trans;
    if (bid == '/buy') then
        local slot = find_empty_slot() == nil and 0x07 or find_empty_slot();
        trans = struct.pack("bbxxihxx", 0x0E, slot, price, item.ItemID);
        --print(string.format('%s "%s" %s %s ID:%s',bid, item.Name, comma_value(price),single == 1 and '[Single]' or '[Stack]',item.ItemID));
    elseif (bid == '/sell') then
        if (auction_box == nil) then
            print('AH Error: Click auction counter or use /ah to initialize sales.');
            return false;
        end
        if (find_empty_slot() == nil) then 
            print('AH Error: No empty slots available.');
            return false;
        end
        local index = find_item(item.ItemID, single == 1 and single or item.StackSize);
        if (index == nil) then 
            print(string.format('AH Error: %s of %s not found in inventory.',single == 1 and 'Single' or 'Stack',item.Name));
            return false;
        end
        trans = struct.pack("bxxxihh", 0x04, price, index, item.ItemID);
        --print(string.format('%s "%s" %s %s ID:%d Ind:%d',bid, item.Name, comma_value(price),single == 1 and '[Single]' or '[Stack]',item.ItemID,index));
    else return false; end
    trans = struct.pack("bbxx", 0x4E, 0x1E) .. trans .. struct.pack("bi32i11", single, 0x00, 0x00);
    if (bid == '/sell') then
        last4E = trans
    end
    trans = trans:totable()
    --print(string.format('modified %s  size [%d]',table.tostring(trans, '%.2X '),#trans));
    AddOutgoingPacket(trans, 0x4E, #trans);
    return true;
end;
