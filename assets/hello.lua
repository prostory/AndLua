require 'import'

local import = import
local proxy = proxy

import 'android.app.*'
import 'android.os.*'
import 'android.widget.*'
import 'android.view.*'

local activity = activity
local LinearLayout = LinearLayout
local TextView = TextView
local EditText = EditText
local Button = Button
local LayoutParams = LinearLayout_LayoutParams
local Gravity = Gravity

local check_attr = function(attr, name, check_type)
    local item = rawget(attr, name)
    if item and type(item) ~= check_type then
        error("attribute '"..name.."' must be "..check_type)
    end
    return item
end

local text = function(attr)
    local tv = TextView(activity)
    if type(attr) == "string" then
        tv:setText(attr)
    elseif type(attr) == "table" then
        local text = check_attr(attr, 'text', 'string')
        if text then
            tv:setText(text)
        end
        local textSize = check_attr(attr, 'textSize', 'number')
        if textSize then
            tv:setTextSize(textSize)
        end
        local textColor = check_attr(attr, 'textColor', 'number')
        if textColor then
            tv:setTextColor(textColor)
        end
        local singleLine = check_attr(attr, 'singleLine', 'boolean')
        if singleLine then
            tv:setSingleLine(singleLine)
        end
        local gravity = check_attr(attr, 'gravity', 'string')
        if gravity then
            local flags = 0
            string.gsub(gravity, "([a-zA-Z_]+)", function(s)
                local type = Gravity[string.upper(s)]
                if type then
                    flags = bit.bor(flags, type)
                else
                    error("gravity can't set to "..s)
                end
            end)
            tv:setGravity(flags)
        end
    end
    
    return tv
end

androidui = {text=text}

local clickListener = function(callback)
    return proxy("View$OnClickListener", {onClick = callback})
end

activity:setTitle('AndLuaDemo')

local layout = LinearLayout(activity)

layout:setOrientation(LinearLayout.VERTICAL)

activity:setContentView(layout)

local tv = text {
    text = "Welcome to AndLua World!, This is a simple Demo",
    textSize = 14,
    textColor = 0x55667788,
    singleLine = false,
    gravity = 'center_horizontal | right'
}

layout:addView(tv)


local et = EditText(activity)

et:setHint("Edit your name!")
et:setSingleLine(true)

layout:addView(et)

local bt = Button(activity)

bt:setLayoutParams(LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT))

bt:setText("start")

bt:setOnClickListener(clickListener(function(v)
    tv:setText("Your name is: " .. et:getText():toString())
end))

layout:addView(bt)