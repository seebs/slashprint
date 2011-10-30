--[[ SlashPrint
     A /print command to evaluate lua expressions

]]--

local SlashPrint = {}

function SlashPrint.printf(fmt, ...)
  print(string.format(fmt or 'nil', ...))
end

function SlashPrint.stringify(val)
  local t = type(val)
  local pretty
  if     t == 'table' then
    pretty = "<table>"
  elseif t == 'string' then
    pretty = string.format("\"%s\"", val)
  elseif t == 'function' then
    pretty = "<function>"
  elseif t == 'boolean' then
    pretty = val and "true" or "false"
  elseif t == 'number' then
    if (math.floor(val) == val) then
      pretty = string.format("%d", val)
    else
      pretty = string.format("%f", val)
    end
  elseif t == 'userdata' then
    pretty = "<userdata>"
  elseif t == 'thread' then
    pretty = "<thread>"
  elseif t == 'nil' then
    pretty = "nil"
  else
    pretty = "<unknown type " .. t .. ">"
  end
  return pretty
end

function SlashPrint.dump(val, indent, comma)
  local t = type(val)
  local ifmt = string.format("%%%ds", (indent + 1) * 2)
  local istr = string.format(ifmt, "")
  local cstr = comma and "," or ""
  if      t == 'table' then
    if SlashPrint.visited[val] then
      SlashPrint.printf("%s%s", istr, "{ table already visited }")
      return
    else
      SlashPrint.visited[val] = true
    end
    -- and let the trailing bit handle this
    if indent < 1 then
      SlashPrint.printf("%s%s", istr, "{")
    end
    for k, v in pairs(val) do
      pretty_k = SlashPrint.stringify(k)
      if type(v) == 'table' then
        SlashPrint.printf("%s  %s: {", istr, pretty_k)
	SlashPrint.dump(v, indent + 1, true)
        SlashPrint.printf("%s  }%s", istr, cstr)
      else
        pretty_v = SlashPrint.stringify(v)
        SlashPrint.printf("%s  %s: %s,", istr, pretty_k, pretty_v)
      end
    end
    if indent < 1 then
      SlashPrint.printf("%s}%s", istr, cstr)
    end
  else
    local pretty = SlashPrint.stringify(val)
    SlashPrint.printf("%s%s%s", istr, pretty, cstr)
  end
end

function SlashPrint.slashcommand(args)
  local func, error = loadstring("return { " .. args .. " }")
  SlashPrint.visited = {}
  if func then
    local status, val = pcall(func)
    if status then
      SlashPrint.printf("%s:", args)
      SlashPrint.visited[val] = true
      local x = table.getn(val)
      if x == 1 then
	-- we only got one arg
        SlashPrint.dump(val[1], 0, false)
      else
        SlashPrint.printf("Got %d result%s:", x, x == 1 and "" or "s")
        for i, v in ipairs(val) do
          SlashPrint.dump(v, 0, false)
        end
      end
    else
      SlashPrint.printf("Error evaluating <%s>: %s", args, val)
    end
  else
    SlashPrint.printf("Couldn't load <%s>: %s", args, error)
  end
end

local slashprint = Command.Slash.Register("print")
if slashprint then
  table.insert(slashprint, { SlashPrint.slashcommand, "SlashPrint", "/print" })
else
  print "Couldn't register /print."
end
