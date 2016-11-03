local ffi = require 'ffi'
local io = io
local log = io.open('log.txt','a')
require 'socket'

ffi.cdef[[
void free(void *ptr);
char *readline(const char *prompt);
void add_history(char *unused);
]]

local ed = ffi.load('edit')

local c = socket.connect('localhost', 3333)

local readfile = function(file)
  local f,err = io.open(file)
  if not f then return nil,err end
  local contents = f:read '*a':gsub('\n','\001')
  f:close()
  return contents
end

local eval = function(line)
  c:send(line..'\n')
  local res = c:receive()
  return res:gsub('\001','\n')
end

local free = ffi.C.free
local readline = ed.readline
local add_history = ed.add_history

eval('require "import"')

local quit = false
while not quit do
    local input = readline("> ")
    add_history(input)
    local line = ffi.string(input)
    local err
    if line then
        log:write(line,'\n')
        local cmd,file = line:match '^%.(.)%s+(.+)$'
        if file then
            local mod
            if cmd == 'm' then
                mod = file
                file = mod:gsub('%.','/')..'.lua'
            end
            line,err = readfile(file)
            if mod and line then
                line = '--mod:'..mod..'\001'..line
            end
        else
            local expr = line:match '^%s*=%s*(.+)$'
            if expr then
                line = 'print('..expr..')'
            end
        end
        if line == 'quit' then
            quit = true
        else
            local res = eval(line)
            log:write(res,'\n')
            io.write(res)
        end
    end
    free(input)
end
c:close()
