require 'socket'

local remote = {}

remote.inited = false

remote.start = function(host, port)
  host = host or 'localhost'
  port = port or 3333
  
  if remote.inited then
    return remote
  end
  
  os.execute('adb forward tcp:3333 tcp:'..port)
  
  local c = assert(socket.connect(host, port))
  
  remote.eval = function(line)
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
    end
    c:send(line)
    local res = c:receive()
    if res then
      local output = res
      if res:sub(1, 8) == '--error:' then
        output = res:sub(9)
      end
      return res:gsub('\001','\n')
    else
      error("Request remote shell error!")
    end
  end
  
  remote.close = function()
    if remote.inited then
      remote.inited = false
      c:close()
    end
  end
  
  remote.inited = true
  
  return remote
end

return remote

