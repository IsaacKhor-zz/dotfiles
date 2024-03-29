-- Copied from dharmapoudel/hammerspoon-config
--
-- Modified by me to support by module loading system
-- and to center the thing correctly
--
-- Updated to the latest revisions of AXMenuItemCmdModifiers

------------------------------------------------------------------------
--/ Cheatsheet Copycat /--
------------------------------------------------------------------------

local masterMode = require("modes.master")

local mod = {}
mod.config = {
  cheatsheetKey = {"⌃", "z"},
  width = 1080,
  height = 800,
  devExtras = false,
}

local newCmdEnum = {
  ["cmd"] = '⌘',
  ["alt"] = '⌥',
  ["ctrl"] = '⌃',
  ["shift"] = '⇧',
}

function modifiersToPrettyString(mods)
  local ret = ""

  if not mods then
    return ret
  end

  for i=1, #mods do
    ret = ret .. " " .. newCmdEnum[mods[i]]
  end
  return ret
end

local function getAllMenuItemsTable(t)
      local menu = {}
      for pos,val in pairs(t) do
          if(type(val)=="table") then
              if(val['AXRole'] =="AXMenuBarItem" and type(val['AXChildren']) == "table") then
                  menu[pos] = {}
                  menu[pos]['AXTitle'] = val['AXTitle']
                  menu[pos][1] = getAllMenuItems(val['AXChildren'][1])
              elseif(val['AXRole'] =="AXMenuItem" and not val['AXChildren']) then
                  if( val['AXMenuItemCmdModifiers'] ~='0' and val['AXMenuItemCmdChar'] ~='') then
                    menu[pos] = {}
                    menu[pos]['AXTitle'] = val['AXTitle']
                    menu[pos]['AXMenuItemCmdChar'] = val['AXMenuItemCmdChar']
                    menu[pos]['AXMenuItemCmdModifiers'] = val['AXMenuItemCmdModifiers']
                  end 
              elseif(val['AXRole'] =="AXMenuItem" and type(val['AXChildren']) == "table") then
                  menu[pos] = {}
                  menu[pos][1] = getAllMenuItems(val['AXChildren'][1])
              end
          end
      end
      return menu
end

local function getAllMenuItems(t)
    local menu = ""
    for pos,val in pairs(t) do
        if(type(val)=="table") then
            -- do not include help menu for now until I find best way to remove menubar items with no shortcuts in them
            if(val['AXRole'] =="AXMenuBarItem" and type(val['AXChildren']) == "table") and val['AXTitle'] ~="Help" then
                menu = menu.."<ul class='col col"..pos.."'>"
                --print("---------------| "..val['AXTitle'].." |---------------")
                menu = menu.."<li class='title'><strong>"..val['AXTitle'].."</strong></li>"
                menu = menu.. getAllMenuItems(val['AXChildren'][1])
                menu = menu.."</ul>"
            elseif(val['AXRole'] =="AXMenuItem" and not val['AXChildren']) then
                if( val['AXMenuItemCmdModifiers'] ~='0' and val['AXMenuItemCmdChar'] ~='') then
                    --print(val['AXMenuItemCmdModifiers'].." | "..val['AXTitle'].." | CmdChar: "..val['AXMenuItemCmdChar'])
                    menu = 
                      menu ..
                      "<li><div class='cmdModifiers'>" ..
                      modifiersToPrettyString(val['AXMenuItemCmdModifiers']) ..
                      " " ..
                      val['AXMenuItemCmdChar'] ..
                      "</div><div class='cmdtext'>" ..
                      " " ..
                      val['AXTitle']..
                      "</div></li>"
                end 
            elseif(val['AXRole'] =="AXMenuItem" and type(val['AXChildren']) == "table") then
                menu = menu..getAllMenuItems(val['AXChildren'][1])
            end
          
        end
    end
    return menu
end

local function generateHtml()
    --local focusedApp= hs.window.frontmostWindow():application()
    local focusedApp = hs.application.frontmostApplication()
    local appTitle = focusedApp:title()
    local allMenuItems = focusedApp:getMenuItems();
    local myMenuItems = getAllMenuItems(allMenuItems)

    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:0; padding:0;}
            html, body{ 
              background-color:#eee;
              font-family: arial;
              font-size: 13px;
            }
            a{
              text-decoration:none;
              color:#000;
              font-size:12px;
            }
            li.title{ text-align:center;}
            ul, li{list-style: inside none; padding: 0 0 5px;}
            footer{
              position: fixed;
              left: 0;
              right: 0;
              height: 48px;
              background-color:#eee;
            }
            header{
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              height:48px;
              background-color:#eee;
              z-index:99;
            }
            footer{ bottom: 0; }
            header hr,
            footer hr {
              border: 0;
              height: 0;
              border-top: 1px solid rgba(0, 0, 0, 0.1);
              border-bottom: 1px solid rgba(255, 255, 255, 0.3);
            }
            .title{
                padding: 15px;
            }
            li.title{padding: 0  10px 15px}
            .content{
              padding: 0 0 15px;
              font-size:12px;
              overflow:hidden;
            }
            .content.maincontent{
            position: relative;
              height: 577px;
              margin-top: 46px;
            }
            .content > .col{
              width: 23%;
              padding:10px 0 20px 20px;
            }
            
            li:after{
              visibility: hidden;
              display: block;
              font-size: 0;
              content: " ";
              clear: both;
              height: 0;
            }
            .cmdModifiers{
              width: 60px;
              padding-right: 15px;
              text-align: right;
              float: left;
              font-weight: bold;
            }
            .cmdtext{
              float: left;
              overflow: hidden;
              width: 165px;
            }
        </style>
        </head>
          <body>
            <header>
              <div class="title"><strong>]]..appTitle..[[</strong></div>
              <hr />
            </header>
            <div class="content maincontent">]]..myMenuItems..[[</div>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.isotope/2.2.2/isotope.pkgd.min.js"></script>
        	<script type="text/javascript">
              var elem = document.querySelector('.content');
              var iso = new Isotope( elem, {
                // options
                itemSelector: '.col',
                layoutMode: 'masonry'
              });
            </script>
          </body>
        </html>
        ]]

    return html
end

local myView = nil

function showCheatsheet() 
  if not myView then
    local max = hs.screen.mainScreen():frame()

    local xpos = (max.w / 2) - (mod.config.width / 2)
    local ypos = (max.h / 2) - (mod.config.height / 2)

    local dim = {x = xpos, y = ypos, w = mod.config.width, h = mod.config.height}

    myView = hs.webview.new(dim, { developerExtrasEnabled = mod.config.devExtras })
      :windowStyle("utility")
      :closeOnEscape(true)
      :html(generateHtml())
      :allowGestures(true)
      :windowTitle("CheatSheets")
      :bringToFront(false)
      :show()
    --myView:asHSWindow():focus()
    --myView:asHSDrawing():setAlpha(.98):bringToFront()
  else
    myView:delete()
    myView=nil
  end
end

function mod.init()
  bind(mod.config.cheatsheetKey, showCheatsheet)
  masterMode.registerEntry(mod.config.cheatsheetKey[2], "Show cheatsheet", showCheatsheet)
end

return mod