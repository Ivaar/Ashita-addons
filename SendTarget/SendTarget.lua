--[[
    Copyright (c) 2015, SblmS2J

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'SendTarget';
_addon.version = '1.0.0.0';
_addon.author = 'Ivaar';

require 'common'
target = require('ffxi.targets');

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
    local args = cmd:args();
    if (args[1] ~= '/sendtarget' and args[1] ~= '/st') then
        return false;
    end
    
    if (#args == 1 or args[2] == 'help') then
        print(string.format('Sends alternate /command <last sub target ID>.\nMacro line 1: /target <st>\nMacro line 2: /st to name command '));
        return true;
    end
    
    if (#args <= 3) then		
        return true;
    end
    
    if (args[2] ~= 'to') then
        return true
    end
    
    if (args[4]:startswith('/') == false) then
        args[4] = '/' .. args[4];
    end
	
    local target = AshitaCore:GetDataManager():GetTarget():GetSubTargetServerId()
	
    if (target ~= nil) then
        local str = '/ms sendto '.. table.concat(args,' ',3) ..' '.. target;
        AshitaCore:GetChatManager():QueueCommand(str, -1);
    else
        print(string.format('Could not find last sub-target. No action performed...'));
    end
    return true;
end);
