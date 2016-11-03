--- a tiny library for benchmark
-- @author spacewander
-- @license MIT
-- @module benchmark
local benchmarklib = require 'benchmarklib'
local cpu_clock = benchmarklib.cpu_clock
local wall_clock = benchmarklib.wall_clock

local _M = {
    _VERSION = '0.1.0',
    --- default format
    FORMAT = "system: %0.3s\tuser: %0.3u\ttotal: %0.3t\treal: %0.3r",
    --- default width of label
    LABEL_WIDTH = 0
}

local default_tms = {
    label = '',
    stime = 0.0,
    utime = 0.0,
    real =  0.0
}
local mt = {}
mt.__index = default_tms
mt.__tostring = function(self)
    return string.format(
        'benchmark.Tms{label: %s\tstime: %f\tutime: %f\ttotal: %f\treal: %f}',
        self.label, self.stime, self.utime, self.total, self.real)
end

--- Create a Tms table.
-- Tms contains below fields:
--
-- * label, default ''
-- * stime system CPU time, default 0.0
-- * utime user CPU time, default 0.0
-- * real wall time, default 0.0
-- * total stime+utime
--
-- @usage
-- Tms{stime=2.0}
-- => Tms{label='', stime=2.0, utime=0.0, total=2.0, real=0.0}
function _M.Tms(args)
    setmetatable(args, mt)
    args.total = args.stime + args.utime
    return args
end

--- Returns the time used to execute the given function as a Tms table.
-- @return a Tms table
--
-- @usage
-- print(bm.measure(function()
--   table.sort(ary)
-- end))
function _M.measure(func, label)
    local stime0, utime0 = cpu_clock()
    local real = _M.realtime(func)
    local stime1, utime1 = cpu_clock()
    return _M.Tms{label=label,
               real=real,
               stime=stime1-stime0,
               utime=utime1-utime0
           }
end

--- Returns the elapsed real time used to execute the given function
--
-- @usage
-- print(bm.realtime(function()
--   table.sort(ary)
-- end))
function _M.realtime(func)
    local t0 = wall_clock()
    func()
    return wall_clock() - t0
end


local Reporter = {}
function Reporter:new(label_width, format, no_gc)
    self.__index = self
    return setmetatable({label_width=label_width, format=format, no_gc=no_gc}, self)
end

local function time_fmt_to_numeric_fmt(time_fmt)
    local ch = {'s', 'u', 't', 'r'}
    local numeric_fmt = time_fmt
    for i = 1, #ch do
        numeric_fmt = string.gsub(numeric_fmt, '(%%[0-9%.%-]*)' .. ch[i], '%1f')
    end
    return numeric_fmt
end

function Reporter:report(func, label)
    if self.no_gc then collectgarbage('stop') end
    local tms = _M.measure(func, label)
    if self.no_gc then collectgarbage('restart') end
    local numeric_fmt = time_fmt_to_numeric_fmt(self.format)
    local output = string.format('%-' .. self.label_width .. 's ' .. numeric_fmt,
        tms.label, tms.utime, tms.stime, tms.total, tms.real)
    print(output)
end

--- Return a reporter to report given benchmark cases.
-- If **no_gc** is not false, it will stop GC while running cases.
-- This reporter will reserve **label_width** leading spaces for labels on each line,
-- and use **format** to format each line.
-- **format** is a C-style format string like '%.3s\t%.3u\t%.3t\t%.3r',
-- where '%s' means system, '%u' means user, '%t' means total, '%r' means real
--
-- @usage
-- local reporter = bm.bm(10, bm.FORMAT, true)
-- reporter:report(function()
--   local size = #ary
--   for i = 1, size do
--      ary[i] = 0
--   end
-- end, 'count up the size first')
function _M.bm(label_width, format, no_gc)
    label_width = label_width or _M.LABEL_WIDTH
    local width = tonumber(label_width)
    if (not width) or math.floor(width) ~= width then
        error('label_width should be an integer')
    end
    format = format or _M.FORMAT
    return Reporter:new(width, format, no_gc)
end

return _M
