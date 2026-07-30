local notes = {}

local function parse_bib_notes(bibpath)
  local f = io.open(bibpath, "r")
  if not f then
    f = io.open(bibpath:match("[^/]+$"), "r")
  end
  if not f then return end
  local content = f:read("*a")
  f:close()
  for entry in content:gmatch("@%w+%b{}") do
    local key = entry:match("@%w+{([%w_]+),")
    if key then
      local note = entry:match("note%s*=%s*{(.-)}")
      if note then
        notes[key] = note
      end
    end
  end
end

local function append_notes(blocks)
  return blocks:walk {
    Div = function (el)
      if el.classes:includes("csl-entry") and el.identifier:match("^ref%-") then
        local key = el.identifier:gsub("^ref%-", ""):gsub("%-%-.*$", "")
        if notes[key] then
          local last = el.content[#el.content]
          if last and last.t == "Para" then
            last.content:insert(pandoc.Space())
            last.content:insert(pandoc.Span(
              {pandoc.Emph({pandoc.Str(notes[key])})},
              pandoc.Attr("", {"bib-note"})
            ))
          end
        end
      end
    end
  }
end

return {{
  Pandoc = function (doc)
    local bib = doc.meta.bibliography
    if bib then
      local path
      if pandoc.utils.type(bib) == "List" then
        path = pandoc.utils.stringify(bib[1])
      else
        path = pandoc.utils.stringify(bib)
      end
      parse_bib_notes(path)
    end

    doc = pandoc.utils.citeproc(doc)
    doc.blocks = append_notes(doc.blocks)
    return doc
  end
}}
