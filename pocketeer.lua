require("oauth")
require("stream");
require("process");
require("dataparser");
require("filesys");
require("io")
require("string")
require("strutil")
require("terminal")
require("net")

VERSION="1.0"

-- API key
key="64045-7bc88d0cc96a4215df7a41c5"

-- Colors for light or dark console background, default is dark

--light background urls are blue, titles are red
 light_urlcolor="~e~b" 
 light_titlecolor="~r" 

--dark background urls are cyan, titles are yellow
 dark_urlcolor="~c" 
 dark_titlecolor="~y" 


-- Uncomment to see http headers
-- process.lu_set("HTTP:Debug","true")


function ReformatTagsForDisplay(Tags)
local Tokens, tag 
local str=""

Tokens=strutil.TOKENIZER(Tags,"|")
tag=Tokens:next()
while tag ~=nil
do
if string.len(tag) > 0 then str=str.."'"..tag.."' " end
tag=Tokens:next()
end

return str
end

function ParseItem(I)
local item={}
local str

str=string.gsub(I:value("resolved_url"),"~","~~")
if str == nil then return nil end

item.url=strutil.unQuote(str)
item.id=I:value("resolved_id")
str=string.gsub(I:value("resolved_title"),"~","~~");
if strutil.strlen(str) ==0 then str=filesys.basename(I:value("resolved_url")) end
item.title=strutil.unQuote(str)

item.wc=I:value("word_count")
if item.wc == nil then item.wc="0" end

str=string.gsub(I:value("excerpt"),"~","~~")
item.excerpt=strutil.unQuote(str)

item.tags=""
Tags=I:open("tags")
if Tags ~= nil
then
	while Tags:next()
	do
		item.tags=item.tags..Tags:value("tag").."|"
	end
end

return item
end
	

function GetItemList(Term, selector, format)
local I, url, S, data, P
local ItemList={}

Term:puts("Please wait, loading item list\n")
url="https://getpocket.com/v3/get?consumer_key="..key.."&access_token="..OA:access_token().."&detailType=complete&sort=oldest"
S=stream.STREAM(url, "r")
data=S:readdoc();
S:close();

P=dataparser.PARSER("json",data)
I=P:open("/list");
while I:next()
do
item=ParseItem(I)
if item ~= nil then table.insert(ItemList, item) end
end

return ItemList
end





-- Does the current item match the selector
function ItemMatches(item, selector)
local pattern, str
local result=false
local value=""
local Tokens

Tokens=strutil.TOKENIZER(selector, ":")
str=Tokens:next()
pattern=Tokens:remaining()

--tags are a special case
if str == "tags" or str == "tag"
then
	Tokens=strutil.TOKENIZER(item.tags, "|")
	value=Tokens:next()
	while value ~= nil
	do
		if strutil.pmatch(pattern, value) > 0 then result=true end
	value=Tokens:next()
	end
else
	if str == "title" then value=item.title
	elseif str == "id" then value=item.id
	elseif str == "url" then value=item.url
	else
	value=item.url
	pattern=selector
	end

	if strutil.pmatch(pattern, value) > 0 then result=true end
	if strutil.pmatch("*"..pattern.."*", value) > 0 then result=true end
end

return result
end




function OutputItemANSI(Term, item)
local Tags, url, wc, id, title, str

Term:puts("~g".. item.id .. "~0 ".. titlecolor  .. item.title .. "~0   ".. urlcolor ..  item.url .."~0".."\n")
Term:puts("~m" .. item.wc .. " words~0: " .. strutil.unQuote(item.excerpt) .. "\n")
if strutil.strlen(item.tags) then Term:puts("~rTags: ".. ReformatTagsForDisplay(item.tags) .."~0\n") end
Term:puts("\n")
	
end


function OutputItemPlain(Term, item)
local Tags, url, wc, id, title

	Term:puts("ID: ".. item.id .. "\n")
	Term:puts("TITLE: ".. item.title .. "\n")
	Term:puts("WORDS: ".. item.wc .. "\n")
	Term:puts("URL: ".. item.url .. "\n")
	Term:puts("EXCERPT: ".. item.excerpt .."\n")
	Term:puts("TAGS: ".. ReformatTagsForDisplay(item.tags).. "\n")
	Term:puts("\n")
end




-- This function outputs items selected by 'selector'
function ShowItems(Term, selector, format)
local Items
local i, item

Items=GetItemList(Term, selector, format)
for i,item in ipairs(Items)
do
if ItemMatches(item, selector)
then
	if format=="plain"
	then
	OutputItemPlain(Term, item)
	else
	OutputItemANSI(Term, item)
	end
end
end

return Items
end





function PocketAction(actions)
local S, url, reply, result=false

url="https://getpocket.com/v3/send?consumer_key="..key.."&access_token="..OA:access_token().."&actions="..strutil.httpQuote(actions)
S=stream.STREAM(url, "")
reply=S:readdoc()
if S:getvalue("HTTP:ResponseCode") == "200" then result=true end

return result
end


function ProcessSingleCommand(cmd, id, args)
local result=false

if cmd == 'tag'
then
	result=PocketAction("[{\"action\": \"tags_add\",\"item_id\": \""..id.."\",\"tags\": \""..args.."\"}]")
elseif cmd=='untag'
then
	result=PocketAction("[{\"action\": \"tags_remove\",\"item_id\": \""..id.."\",\"tags\": \""..args.."\"}]")
elseif cmd=='rm' or cmd=='del' or cmd=='delete'
then
	result=PocketAction("[{\"action\": \"delete\",\"item_id\": \""..id.."\"}]")
end

return result
end


function PocketAddItem(Term, selector, args)

	if PocketAction("[{\"action\": \"add\",\"url\": \""..selector.."\",\"tags\": \""..args.."\"}]")
	then
		Term:puts("~gOKAY~0 Added item\n")
	else
		Term:puts("~rFAIL~0 Item add failed\n")
	end

end



function ProcessCommandOnItems(Term, cmd, args, items, selector)
local i, item

	for i,item in ipairs(items)
	do
	if ItemMatches(item, selector)
	then
		if cmd == "show" or cmd == "ls" or cmd == "list" then OutputItemANSI(Term, item) 
		elseif ProcessSingleCommand(cmd, item.id, args)
		then
			Term:puts("~gOKAY~0 ".. cmd .. " item: ".. item.id.." "..item.url.."\n")
		else
			Term:puts("~gFAIL~0 ".. cmd .. " item: ".. item.id.." "..item.url.."\n")
		end
	end
	end
end




function ReformatSelector(selector)

if selector == nil then selector='*' 
elseif string.len(selector) == 0 then selector='*'
elseif string.sub(selector,1,5) =="http:" or string.sub(selector,1,6) =="https:" then selector="url:"..selector
elseif string.sub(selector,1,3) ~= "id:" and string.sub(selector,1,6) ~= "title:" and string.sub(selector,1,5) ~= "tags:" and string.sub(selector,1,4) ~= "tag:" then selector="id:"..selector
end

return selector
end



function PocketInteractiveHelp()

print()
print("commands:");
print("add <url> <tags>     - add a url to your pocket");
print("del <select>         - delete an item from your pocket");
print("delete <select>      - delete an item from your pocket");
print("rm <select>          - delete an item from your pocket");
print("ls <select>          - list items in pocket");
print("list <select>        - list items in pocket");
print("show <select>        - list items in pocket");
print()
print("The <select> argument represents a selector, which can have one of the following forms:")
print("  title:<title>")
print("  id:<id>")
print("  <url>")
print()

end


function ProcessCommand(Term, cmd, selector, args, Items)


if cmd == "add" then 
	PocketAddItem(Term, selector, args);
elseif cmd=='quit' or cmd=='exit'
then
	Term:reset()
	process.exit(0)
elseif cmd=='tag' or cmd=='untag' or cmd=='rm' or cmd=='del' or cmd=='delete' or cmd=='ls' or cmd=='list' or cmd=='show'
then
	if Items==nil then Items=GetItemList(Term, selector, format) end
	ProcessCommandOnItems(Term, cmd, args, Items, selector)
elseif cmd=="help"
then
	PocketInteractiveHelp()
else
	Term:puts("~rUNKNOWN COMMAND~0\n")
end

end



function PocketInteractive(Term)
local line, Tokens, cmd, selector, args, Items

Items=ShowItems(Term, "*", "")
while 1 == 1
do
Term:flush()
line=Term:prompt(">> ")

Tokens=strutil.TOKENIZER(line, " ")

cmd=Tokens:next()
selector=Tokens:next()
args=Tokens:remaining()

selector=ReformatSelector(selector)

ProcessCommand(Term, cmd, selector, args, Items)
end

end


function PrintCommandLineHelp()

print()
print("pocketeer.lua: v"..VERSION);
print("lua pocketeer.lua add <url> <tags>      - add a url to your pocket");
print("lua pocketeer.lua del <select>          - delete an item from your pocket");
print("lua pocketeer.lua delete <select>       - delete an item from your pocket");
print("lua pocketeer.lua rm <select>           - delete an item from your pocket");
print("lua pocketeer.lua tag <select> <tags>   - add a tag to items");
print("lua pocketeer.lua untag <select> <tags> - remove a tag from items");
print("lua pocketeer.lua ls <select>           - list items in pocket (color output)");
print("lua pocketeer.lua list <select>         - list items in pocket (color output)");
print("lua pocketeer.lua plain <select>        - list items in pocket (plain text output)");
print("lua pocketeer.lua                       - this help");
print()
print("The <select> argument is an optional selector, which can have one of the following forms:")
print("  title:<title>")
print("  id:<id>")
print("  tag:<tag>")
print("  url:<url>")
print()
print("The extra argument '-proxy <proxy url>' allows specifying the use of a proxy-server. Supported proxy types are 'https', 'socks4', 'socks5', and 'sshtunnel'. URL format can include username and password. e.g. 'sshtunnel:bill:secret1234@sshhost:1022'.")
print("The 'ls' and 'list' commands can accept the switches '-light' and '-dark' for choosing colors appropriate to a light or dark background")
print()

end



function PocketOAuth()
local OA

OA=oauth.OAUTH("getpocket.com","pocket",key, "","", "");
if OA:load() == 0 
then
OA:set("redirect_uri",strutil.httpQuote("http://127.0.0.1:8989/"));
OA:stage1("https://getpocket.com/v3/oauth/request");
print("OAUTH Authorization required. Please goto the following URL in a webbrowser on this machine");
print("GOTO: ".. OA:auth_url());
OA:listen(8989, "https://getpocket.com/v3/oauth/authorize");
print("OAUTH handshake complete. Resuming processing...")
end

return OA
end


function ParseCommandLine(arg)
local cmd, i, str
local selector=""
local extra=""

cmd=arg[1]

for i=2,#arg,1
do
	if arg[i]=="-proxy"
	then
		i=i+1
		net.setProxy(arg[i])
		print("SetProxy: "..arg[i].."\r\n")
		arg[i]=""
	elseif arg[i]=="-dark"
	then
		urlcolor=dark_urlcolor
		titlecolor=dark_titlecolor
	elseif arg[i]=="-light"
	then
		urlcolor=light_urlcolor
		titlecolor=light_titlecolor
	else
		if strutil.strlen(selector) ==0 
		then
			selector=arg[i]
		else
			extra=extra.." "..arg[i]
		end
	end
end

return cmd,selector,extra
end


urlcolor=dark_urlcolor
titlecolor=dark_titlecolor

--[[  MAIN STARTS HERE ]]--
Term=terminal.TERM()

cmd,selector,extra=ParseCommandLine(arg)
selector=ReformatSelector(selector)
if strutil.strlen(cmd) ==0 then PrintCommandLineHelp()
else
OA=PocketOAuth()
if cmd == "interactive" then PocketInteractive(Term)
elseif cmd == "add" then	PocketAddItem(Term, selector, extra);
elseif cmd == "ls" or cmd == "list" then ShowItems(Term, selector, "") 
elseif cmd =="plain" then ShowItems(Term, selector, "plain") 
elseif cmd=="del" or cmd=="delete" or cmd=="rm" or cmd=="tag" or cmd=="untag" then
ProcessCommand(Term, cmd, selector, extra, nil)
end

end





