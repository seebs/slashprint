--[[ SlashPrint
     A /print command to evaluate lua expressions

]]--

local addoninfo, SlashPrint = ...

SlashPrint.aborted = false
SlashPrint.linemax = 700

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
    pretty = tostring(val)
  elseif t == 'boolean' then
    pretty = val and "true" or "false"
  elseif t == 'number' then
    if (math.floor(val) == val) then
      pretty = string.format("%d", val)
    else
      pretty = string.format("%f", val)
    end
  elseif t == 'userdata' then
    pretty = tostring(val)
  elseif t == 'thread' then
    pretty = tostring(val)
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
  if SlashPrint.aborted then
    if t == 'table' then
      SlashPrint.visited[val] = true
    end
    return
  end
  if SlashPrint.linecount >= 700 then
    SlashPrint.printf("... Too many lines, stopping.")
    SlashPrint.aborted = true
    return
  end
  if      t == 'table' then
    SlashPrint.visited[val] = true
    -- and let the trailing bit handle this
    if indent < 1 then
      SlashPrint.printf("%s%s", istr, "{")
      SlashPrint.linecount = SlashPrint.linecount + 1
    end
    for k, v in pairs(val) do
      if SlashPrint.aborted then
        break
      end
      if SlashPrint.linecount >= SlashPrint.linemax then
	SlashPrint.printf("... Too many lines, stopping.")
	SlashPrint.aborted = true
        break
      end
      pretty_k = SlashPrint.stringify(k)
      if type(v) == 'table' then
	if SlashPrint.visited[v] then
          SlashPrint.printf("%s  %s: { %s already visited }", istr, pretty_k, tostring(v))
          SlashPrint.linecount = SlashPrint.linecount + 1
	elseif indent + 1 >= SlashPrint.maxdepth then
          SlashPrint.printf("%s  %s: { %s (depth limit reached) }", istr, pretty_k, tostring(v))
          SlashPrint.linecount = SlashPrint.linecount + 1
	else
          SlashPrint.printf("%s  %s: {", istr, pretty_k)
          SlashPrint.linecount = SlashPrint.linecount + 1
	  SlashPrint.dump(v, indent + 1, true)
          SlashPrint.printf("%s  }%s", istr, cstr)
          SlashPrint.linecount = SlashPrint.linecount + 1
	end
      else
        pretty_v = SlashPrint.stringify(v)
        SlashPrint.printf("%s  %s: %s,", istr, pretty_k, pretty_v)
	SlashPrint.linecount = SlashPrint.linecount + 1
      end
    end
    if indent < 1 then
      SlashPrint.printf("%s}%s", istr, cstr)
    end
  else
    local pretty = SlashPrint.stringify(val)
    SlashPrint.printf("%s%s%s", istr, pretty, cstr)
    SlashPrint.linecount = SlashPrint.linecount + 1
  end
end

function SlashPrint.slashcommand(args)
  SlashPrint.linecount = 0
  SlashPrint.aborted = false
  if not args then
    SlashPrint.printf("Usage error.")
    return
  end
  SlashPrint.maxdepth = args['d'] or 10
  local func, error = loadstring("return { " .. args['leftover'] .. " }")
  SlashPrint.visited = {}
  if func then
    local status, val = pcall(func)
    if status then
      SlashPrint.printf("%s:", args['leftover'])
      SlashPrint.visited[val] = true
      local x = table.getn(val)
      if x == 1 then
	-- we only got one arg
        SlashPrint.dump(val[1], 0, false)
      else
        SlashPrint.printf("Got %d result%s:", x, x == 1 and "" or "s")
        for i, v in ipairs(val) do
	  if SlashPrint.aborted then
	    break
	  end
          SlashPrint.dump(v, 0, false)
        end
      end
      if SlashPrint.aborted then
        SlashPrint.printf("Stopped after %d lines.", SlashPrint.linecount)
      end
    else
      SlashPrint.printf("Error evaluating <%s>: %s", args['leftover'], val)
    end
  else
    SlashPrint.printf("Couldn't load <%s>: %s", args['leftover'], error)
  end
end

Library.LibGetOpt.makeslash("d#", "SlashPrint", "print", SlashPrint.slashcommand)
