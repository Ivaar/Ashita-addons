--[[
Copyright (c) 2014, Seth VanHeulen
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

-- addon information

_addon.name = 'boxdestroyer'
_addon.version = '1.0.4'
_addon.author = 'Seth VanHeulen (Acacia@Odin)'

-- Port to Ashita maintained by: Ivaar

-- load message constants
require('common')

require('messages')

-- global constants

default = {
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
    40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
    50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
    60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
    70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
    80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
    90, 91, 92, 93, 94, 95, 96, 97, 98, 99
}

range_mods = {
    [1022] = 8, -- 8, 32 -- thiefs tools
    [1023] = 6, -- 6, 24 -- living key
    [1115] = 4, -- 4, 16 -- skeleton key
}
-- global variables

box = {}
range = {}
zone_id = AshitaCore:GetDataManager():GetParty():GetMemberZone(0)

-- filter helper functions

function greater_less(id, greater, num)
    if box[id] == nil then
        box[id] = default
    end
    local new = {}
    for _,v in pairs(box[id]) do
        if greater and v > num or not greater and v < num then
            table.insert(new, v)
        end
    end
    return new
end

function even_odd(id, div, rem)
    if box[id] == nil then
        box[id] = default
    end
    local new = {}
    for _,v in pairs(box[id]) do
        if (math.floor(v / div) % 2) == rem then
            table.insert(new, v)
        end
    end
    return new
end

function equal(id, first, num)
    if box[id] == nil then
        box[id] = default
    end
    local new = {}
    for _,v in pairs(box[id]) do
        if first and math.floor(v / 10) == num or not first and (v % 10) == num then
            table.insert(new, v)
        end
    end
    return new
end

-- display helper function

function display(id, chances)
    if #box[id] == 90 then
        print('\31\207possible combinations: 10~99')
    else
        print('\31\207possible combinations: ' .. table.concat(box[id], ' \31\207'))
    end
    local remaining = math.floor(#box[id] / math.pow(2, (chances - 1)))
    if remaining == 0 then
        remaining = 1
    end
    print(string.format('\31\207best guess: %d (%d%%)',box[id][math.ceil(#box[id] / 2)], 1 / remaining * 100))
end

function locked_box_menu(menu_id)
    if menu_id > 999 and menu_id < 1048 then
        return menu_id % 3 == 0
    end
end

-- ID obtaining helper function
function get_id(zone_id,str)
    return messages[zone_id] + offsets[str]
end

-- event callback functions

function check_incoming_chunk(id, size, packet)
    if id == 0x0A then
        zone_id = struct.unpack('H',packet,49)
    elseif messages[zone_id] then
        if id == 0x0B then
            box = {}
            range = {}
        elseif id == 0x2A then
            local box_id = struct.unpack('I', packet, 5)
            local param0 = struct.unpack('I', packet, 9)
            local param1 = struct.unpack('I', packet, 13)
            local param2 = struct.unpack('I', packet, 17)
            local message_id = struct.unpack('H', packet, 27) % 0x8000
            if get_id(zone_id, 'greater_less') == message_id then
                box[box_id] = greater_less(box_id, param1 == 0, param0)
            elseif get_id(zone_id, 'second_even_odd') == message_id then
                box[box_id] = even_odd(box_id, 1, param0)
            elseif get_id(zone_id, 'first_even_odd') == message_id then
                box[box_id] = even_odd(box_id, 10, param0)
            elseif get_id(zone_id, 'range') == message_id then
                -- lower bound (param0) = solution - RANDINT(5,20)
                -- upper bound (param1) = solution + RANDINT(5,20)
                -- param0 + 21 > solution > param0 + 4
                -- param1 - 4  > solution > param1 - 21

                -- Thief tools are the same as normal ranges but with larger bounds.
                -- lower bound (param0) = solution - RANDINT(8,32)
                -- upper bound (param1) = solution + RANDINT(8,32)
                -- param0 + 33 > solution > param0 + 7
                -- param1 - 7  > solution > param1 - 33

                -- if the bound is less than 11 or greater than 98, the message changes to "greater" or "less" respectively
                box[box_id] = greater_less(box_id, true, math.max(param1-4*range[box_id],param0+range[box_id]) - 1)
                box[box_id] = greater_less(box_id, false, math.min(param0+4*range[box_id],param1-range[box_id]) + 1)
                observed[box_id].range = true
            elseif get_id(zone_id,'less') == message_id then
                -- Less is a range with 9 as the lower bound
                box[box_id] = greater_less(box_id, true, math.max(param0-4*range[box_id], 10) - 1)
                box[box_id] = greater_less(box_id, false, math.min(10+4*range[box_id],param0-range[box_id]) + 1)
                observed[box_id].range = true
            elseif get_id(zone_id,'greater') == message_id then
                -- Greater is a range with 100 as the upper bound
                box[box_id] = greater_less(box_id, true, math.max(99-4*range[box_id],param0+range[box_id]) - 1)
                box[box_id] = greater_less(box_id, false, math.min(param0+4*range[box_id], 99) + 1)
            elseif get_id(zone_id, 'equal') == message_id then
                local new = equal(box_id, true, param0)
                local duplicate = param0 * 10 + param0
                for k,v in pairs(new) do
                    if v == duplicate then
                        table.remove(new, k)
                    end
                end
                for _,v in pairs(equal(box_id, false, param0)) do table.insert(new, v) end
                table.sort(new)
                box[box_id] = new
            elseif get_id(zone_id,'second_multiple') == message_id then
                local new = equal(box_id, false, param0)
                for _,v in pairs(equal(box_id, false, param1)) do table.insert(new, v) end
                for _,v in pairs(equal(box_id, false, param2)) do table.insert(new, v) end
                table.sort(new)
                box[box_id] = new
            elseif get_id(zone_id,'first_multiple') == message_id then
                local new = equal(box_id, true, param0)
                for _,v in pairs(equal(box_id, true, param1)) do table.insert(new, v) end
                for _,v in pairs(equal(box_id, true, param2)) do table.insert(new, v) end
                table.sort(new)
                box[box_id] = new
            elseif get_id(zone_id, 'success') == message_id or get_id(zone_id, 'failure') == message_id then
                box[box_id] = nil
            end
        elseif id == 0x34 and locked_box_menu(struct.unpack('H', packet, 0x2D)) then
            local box_id = struct.unpack('H', packet, 41)
            if box[box_id] == nil then
                box[box_id] = default
            end
            display(box_id, packet:byte(9))
        elseif id == 0x5B then
            box[struct.unpack('I', packet, 17)] = nil
            range[struct.unpack('I', packet, 17)] = nil
        end
    end
    return false
end

function check_outgoing_chunk(id, size, packet)
    if not messages[zone_id] then return false end

    if id == 0x036 and
        GetEntity(struct.unpack('H', packet, 0x29)).Name == 'Treasure Casket' and -- models[1] == 966
        AshitaCore:GetDataManager():GetPlayer():GetMainJob() == 6 then

        for i = 1,9 do
            local num = range_mods[AshitaCore:GetDataManager():GetInventory():GetItem(0, packet:byte(0x30+i)).Id]
            if num then
                range[struct.unpack('I', packet, 0x05)] = num
                break
            end
        end
    elseif id == 0x05B and locked_box_menu(struct.unpack('H', packet, 0x13)) and struct.unpack('I', packet, 0x09) == 258 then
        -- examine the chest
        range[struct.unpack('I', packet, 0x05)] = 5
    end
    return false
end
-- register event callbacks

ashita.register_event('incoming_packet', check_incoming_chunk)
ashita.register_event('outgoing_packet', check_outgoing_chunk)
