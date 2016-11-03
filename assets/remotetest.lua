--remote: remotetest.lua

import 'android.view.*'
import 'android.widget.*'

local layout = dofile '/sdcard/layout.lua'

local main = layout{
  LinearLayout,
  layout_width="match_parent",
  layout_height="match_parent",
  orientation="vertical",
  {
    TextView,
    id="qqgroup",
    layout_width="wrap_content",
    layout_height="wrap_content",
    text="qqgroup",
    textColor="#FFFFFF",
  },
  {
    Button,
    id="button",
    layout_width="wrap_content",
    layout_height="wrap_content",
    text="start",
    textColor="#FFFFFF"
  },
  {
    EditText,
    id="edit",
    layout_width="match_parent",
    layout_height="wrap_content",
    hint="hello",
    text="sdfdfsjdfkdj",
    textColor="#FFFF00FF"
  },
  {
    RelativeLayout,
    layout_width="match_parent",
    layout_height="match_parent",
    {
      TextView,
      id="re_text",
      text="hello, In RelaytiveLayout",
      layout_width="wrap_content",
      layout_height="wrap_content",
      layout_alignParentRight="true",
    }
  }
}

local function hex(c)
  if c > 0x7fffffff then
    return c - 0x100000000
  elseif c > 0x7fffff then
    return c - 0x1000000
  else
    return c
  end
end

local ClickListener = function(callback)
    return proxy("View$OnClickListener", {onClick = callback})
end

button:setOnClickListener(ClickListener(function(v) 
  re_text:setText("Clicked Button")
  re_text:setTextColor(hex(0xff0000))
end))

activity:setContentView(main)