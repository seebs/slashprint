--[[ SlashPrint
     A /print command to evaluate lua expressions

     Also a dump function that drops things into a table.

]]--

local addoninfo, SlashPrint = ...

SlashPrint.aborted = false
SlashPrint.maxlines = 10000
SlashPrint.maxdepth = 10

function SlashPrint.printf(fmt, ...)
  print(string.format(fmt or 'nil', ...))
end

function SlashPrint.append(tab, fmt, ...)
  table.insert(tab, string.format(fmt or 'nil', ...))
end

function SlashPrint.stringify(val, tablekey)
  local t = type(val)
  local pretty
  if     t == 'table' then
    pretty = "<table>"
  elseif t == 'string' then
    if tablekey and string.match(val, '^[_%a][_%a%d]*$') then
      pretty = string.format("%s", val)
    else
      pretty = string.format("\"%s\"", val)
    end
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

function SlashPrint.empty(tab)
  for k, v in pairs(tab) do
    if v ~= nil or SlashPrint.verbose then
      return false
    end
  end
  return true
end

function SlashPrint.dump(tab, val, indent, comma)
  local t = type(val)
  if not indent then
    SlashPrint.visited = {}
    indent = 0
  end
  local ifmt = string.format("%%%ds", (indent + 1) * 2)
  local istr = string.format(ifmt, "")
  local cstr = comma and "," or ""
  if SlashPrint.aborted then
    if t == 'table' then
      SlashPrint.visited[val] = true
    end
    return
  end
  if #tab >= SlashPrint.maxlines then
    SlashPrint.append(tab, "... Too many lines, stopping.")
    SlashPrint.aborted = true
    return
  end
  if      t == 'table' then
    SlashPrint.visited[val] = true
    -- and let the trailing bit handle this

    if SlashPrint.empty(val) then
      SlashPrint.append(tab, "%s  {}%s", istr, cstr)
      return
    end
    if indent < 1 then
      SlashPrint.append(tab, "%s%s", istr, "{")
    end
    for k, v in pairs(val) do
      if SlashPrint.aborted then
        break
      end
      if #tab >= SlashPrint.maxlines then
	SlashPrint.append(tab, "... Too many lines, stopping.")
	SlashPrint.aborted = true
        break
      end
      pretty_k = SlashPrint.stringify(k, true)
      if type(v) == 'table' then
	if SlashPrint.visited[v] then
          SlashPrint.append(tab, "%s  %s = { %s already visited }", istr, pretty_k, tostring(v))
	elseif indent + 1 >= SlashPrint.maxdepth then
          SlashPrint.append(tab, "%s  %s = { %s (depth limit reached) }", istr, pretty_k, tostring(v))
	else
	  if SlashPrint.empty(v) then
            SlashPrint.append(tab, "%s  %s = {},", istr, pretty_k)
	  else
            SlashPrint.append(tab, "%s  %s = {", istr, pretty_k)
	    SlashPrint.dump(tab, v, indent + 1, true)
            SlashPrint.append(tab, "%s  },", istr)
	  end
	end
      else
        if v ~= nil or SlashPrint.verbose then
          pretty_v = SlashPrint.stringify(v, true)
          SlashPrint.append(tab, "%s  %s = %s,", istr, pretty_k, pretty_v)
        end
      end
    end
    if indent < 1 then
      SlashPrint.append(tab, "%s}%s", istr, cstr)
    end
  else
    local pretty = SlashPrint.stringify(val)
    SlashPrint.append(tab, "%s%s%s", istr, pretty, cstr)
  end
end

function SlashPrint.slashcommand(args)
  SlashPrint.aborted = false
  if not args then
    SlashPrint.printf("Usage error.")
    return
  end
  SlashPrint.maxdepth = args.d or 10
  SlashPrint.verbose = args.v
  local func, error = loadstring("return { " .. args.leftover .. " }")
  SlashPrint.visited = {}
  if func then
    local status, val = pcall(func)
    local pretty
    if status then
      SlashPrint.printf("%s:", args['leftover'])
      SlashPrint.visited[val] = true
      if #val == 1 then
	-- we only got one arg
	pretty = {}
        SlashPrint.dump(pretty, val[1])
	for idx, v in ipairs(pretty) do
	  print(v)
	  if idx > 1000 then
	    SlashPrint.printf("... %d more lines omitted.",
	      #pretty - 1001)
	    break
	  end
	end
      else
        SlashPrint.printf("Got %d result%s:", #val, #val == 1 and "" or "s")
        for i, v in ipairs(val) do
	  if SlashPrint.aborted then
	    break
	  end
	  pretty = {}
          SlashPrint.dump(pretty, v)
	  for idx, v in ipairs(pretty) do
	    print(v)
	    if idx > 1000 then
	      SlashPrint.printf("... %d more lines omitted.",
	      	#pretty - 1001)
	      break
	    end
	  end
        end
      end
      if SlashPrint.aborted then
        SlashPrint.printf("Stopped after %d lines.", #pretty)
      end
    else
      SlashPrint.printf("Error evaluating <%s>: %s", args['leftover'], val)
    end
  else
    SlashPrint.printf("Couldn't load <%s>: %s", args['leftover'], error)
  end
end

Library.LibGetOpt.makeslash("d#v", "SlashPrint", "print", SlashPrint.slashcommand)
