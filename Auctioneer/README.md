Auction house bidding tool "Auctioneer" - Addon for Ashita.

Allows you to perform auction house actions with commands, much like "Bidder" with additional functionality. Displays a text object with sales information when opening ah menu (if text object is set to show).

buy [item name] [stack] [price] -- buy an item on auction house

sell [item name] [ stack] [price] -- sell an item, must open ah once after addon has loaded/players logged in.

[item name] - Accepts auto-translate, short or full item name.
[Stack] - "stack" or "1" or "single" or "0"
[price] - CSV and EU decimal mark are optional. e.g. 100000 or 100,000 or 100.000

inbox / ibox - open delivery inbox

outbox / obox - open delivery outbox

ah - open AH menu

ah clear - clear sold/unsold status

ah show/ah hide - show or hide text object, accepts following arguments to customize displayed information, show as little or as much as you like.

timer - display timer counting down/up to/from end of auction/time of sale.
date - date and time the auction ends/item returned/item sold
price - display your asking price
empty - show/hide empty slots
slot - display slot number next to item entry

ah save - save settings related to text object

check settings file for more customization options.

TODO:

Expand delivery boxes beyond auction house zones (list mog house zones, other delivery areas).
Block sell confirm window when injecting sell packet (only occurs inside sell menu).
Adjust delays.
