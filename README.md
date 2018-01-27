## pocketeer.lua: copyright Colum Paget 2018
contact: colums.projects@gmail.com
license: GPLv3

This is just a basic command-line tool for the getpocket.com API. It lets you add, remove, tag, untag and list items.


#BUILDING
Pocketeer requires both libUseful and libUseful-lua to be installed. These are available at:

```
https://www.github.com/ColumPaget/libUseful
https://www.github.com/ColumPaget/libUseful-lua
```

you will also need SWIG installed to compile libUseful-lua (http://www.swig.org)

## USAGE
```
lua pocketeer.lua add <url> <tags>      - add a url to your pocket
lua pocketeer.lua del <select>          - delete an item from your pocket
lua pocketeer.lua delete <select>       - delete an item from your pocket
lua pocketeer.lua rm <select>           - delete an item from your pocket
lua pocketeer.lua tag <select> <tags>   - add a tag to items
lua pocketeer.lua untag <select> <tags> - remove a tag from items
lua pocketeer.lua ls <select>           - list items in pocket (color output)
lua pocketeer.lua list <select>         - list items in pocket (color output)
lua pocketeer.lua plain <select>        - list items in pocket (plain text output)
lua pocketeer.lua                       - this help

The <select> argument is an optional selector, which can have one of the following forms:
  title:<title>
  id:<id>
  tag:<tag>
  url:<url>
```

The extra argument `-proxy <proxy url>` allows specifying the use of a proxy-server. Supported proxy types are 'https', 'socks4', 'socks5', and 'sshtunnel'. URL format can include username and password. e.g. `sshtunnel:bill:secret1234@sshhost:1022`.
The 'ls' and 'list' commands can accept the switches '-light' and '-dark' for choosing colors appropriate to a light or dark background

