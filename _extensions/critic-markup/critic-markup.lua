-- Critic Markup filter for Quarto
-- Allows rendering markup, original or edited versions.

local critic_mode = 'markup'
local add, adde, rm, rme, rmeadd, mark, marke, comm, comme, rules
local st_b, st_e = '{', '}'
local en_dash = utf8.char(0x2013)

local scriptcode = [[
<div id="criticnav">
<ul>
<li id="markup-button">Markup</li>
<li id="original-button">Original</li>
<li id="edited-button">Edited</li>
</ul>
</div>

<script type="text/javascript">
  function critic() {
      $('.content').addClass('markup');
      $('#markup-button').addClass('active');
      $('ins.break').unwrap();
      $('span.critic.comment').wrap('<span class="popoverc" /></span>');
      $('span.critic.comment').before('&#8225;');
  }

  function original() {
      $('#original-button').addClass('active');
      $('#edited-button').removeClass('active');
      $('#markup-button').removeClass('active');

      $('.content').addClass('original');
      $('.content').removeClass('edited');
      $('.content').removeClass('markup');
  }

  function edited() {
      $('#original-button').removeClass('active');
      $('#edited-button').addClass('active');
      $('#markup-button').removeClass('active');

      $('.content').removeClass('original');
      $('.content').addClass('edited');
      $('.content').removeClass('markup');
  }

  function markup() {
      $('#original-button').removeClass('active');
      $('#edited-button').removeClass('active');
      $('#markup-button').addClass('active');

      $('.content').removeClass('original');
      $('.content').removeClass('edited');
      $('.content').addClass('markup');
  }

  var o = document.getElementById("original-button");
  var e = document.getElementById("edited-button");
  var m = document.getElementById("markup-button");

  window.onload = critic();
  o.onclick = original;
  e.onclick = edited;
  m.onclick = markup;
</script>
]]

local latexcode = nil

local function setup_markup()
  if FORMAT:match 'html' then
    add = pandoc.RawInline('html', '<ins>')
    adde = pandoc.RawInline('html', '</ins>')
    rm = pandoc.RawInline('html', '<del>')
    rme = pandoc.RawInline('html', '</del>')
    rmeadd = pandoc.RawInline('html', '</del><ins>')
    mark = pandoc.RawInline('html', '<mark>')
    marke = pandoc.RawInline('html', '</mark>')
    comm = pandoc.RawInline('html', '<span class="critic comment">')
    comme = pandoc.RawInline('html', '</span>')
  elseif FORMAT:match 'latex' then
    add = pandoc.RawInline('latex', '\\criticmarkupadd{')
    adde = pandoc.RawInline('latex', '}')
    rm = pandoc.RawInline('latex', '\\criticmarkuprm{')
    rme = pandoc.RawInline('latex', '}')
    rmeadd = pandoc.RawInline('latex', '}\\criticmarkupadd{')
    mark = pandoc.RawInline('latex', '\\criticmarkupmark{')
    marke = pandoc.RawInline('latex', '}')
    comm = pandoc.RawInline('latex', '\\criticmarkupcomm{')
    comme = pandoc.RawInline('latex', '}')
    if critic_mode == 'markup' then
      latexcode = [[
\usepackage{pdfcomment}
\makeatletter
\newcommand{\criticmarkupadd}[1]{\pdfmarkupcomment[markup=Highlight,color={0.838431 0.913725 0.734902}]{#1}{}}
\newcommand{\criticmarkuprm}[1]{\pdfmarkupcomment[markup=Highlight,color={0.887059 0.673725 0.673725}]{#1}{}}
\newcommand{\criticmarkupmark}[1]{\pdfmarkupcomment[markup=Highlight,color={1 0.99216 0.21961}]{#1}{}}
\newcommand{\criticmarkupcomm}[1]{\pdfcomment[icon=Comment, color={0.89804 0.69020 0}]{#1}}
\makeatother
]]
    elseif critic_mode == 'original' then
      latexcode = [[
\makeatletter
\newcommand{\criticmarkupadd}[1]{}
\newcommand{\criticmarkuprm}[1]{#1}
\newcommand{\criticmarkupmark}[1]{#1}
\newcommand{\criticmarkupcomm}[1]{}
\makeatother
]]
    else -- edited
      latexcode = [[
\makeatletter
\newcommand{\criticmarkupadd}[1]{#1}
\newcommand{\criticmarkuprm}[1]{}
\newcommand{\criticmarkupmark}[1]{#1}
\newcommand{\criticmarkupcomm}[1]{}
\makeatother
]]
    end
  end

  rules = {
    ['{++'] = add,
    ['{--'] = rm,
    ['{' .. en_dash] = rm,
    ['{=='] = mark,
    ['{>>'] = comm,
    ['{~~'] = rm,
    ['++}'] = adde,
    ['--}'] = rme,
    [en_dash .. '}'] = rme,
    ['==}'] = marke,
    ['<<}'] = comme,
    ['~~}'] = rme,
    ['~>'] = rmeadd,
  }
end

-- determine whether we should include content based on current critic state
local function include_for_mode(state)
  if state == 'normal' or state == 'mark' then
    return true
  elseif state == 'add' then
    return critic_mode == 'edited'
  elseif state == 'del' then
    return critic_mode ~= 'edited'
  elseif state == 'sub_orig' then
    return critic_mode ~= 'edited'
  elseif state == 'sub_new' then
    return critic_mode == 'edited'
  elseif state == 'comm' then
    return false
  end
  return true
end

-- process a string segment, handling critic markers that may appear within it
local function process_text_segment(text, state)
  local out = {}
  local i = 1
  while i <= #text do
    -- opening markers (only meaningful outside a region)
    if state == 'normal' then
      if text:sub(i, i + 2) == '{++' then
        state = 'add'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '{--' then
        state = 'del'
        i = i + 3
        goto continue
      elseif text:sub(i, i) == '{' and text:sub(i + 1, i + 1) == en_dash then
        -- en dash variant for deletions: {–
        state = 'del'
        i = i + 2
        goto continue
      elseif text:sub(i, i + 2) == '{==' then
        state = 'mark'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '{>>' then
        state = 'comm'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '{~~' then
        state = 'sub_orig'
        i = i + 3
        goto continue
      end
    end

    -- mid substitution marker
    if state == 'sub_orig' and text:sub(i, i + 1) == '~>' then
      state = 'sub_new'
      i = i + 2
      goto continue
    end

    -- closing markers
    if state ~= 'normal' then
      if text:sub(i, i + 2) == '++}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '--}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i) == en_dash and text:sub(i + 1, i + 1) == '}' then
        state = 'normal'
        i = i + 2
        goto continue
      elseif text:sub(i, i + 2) == '==}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '<<}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '~~}' then
        state = 'normal'
        i = i + 3
        goto continue
      end
    end

    -- regular character
    local ch = text:sub(i, i)
    if include_for_mode(state) and ch ~= '' then
      out[#out + 1] = ch
    end
    i = i + 1
    ::continue::
  end
  return table.concat(out), state
end

-- Process a list of inline elements to remove/keep critic content for PDF original/edited
-- Merge adjacent Str tokens so critic markers aren't split across tokens
local function merge_adjacent_str(inlines)
  local merged = pandoc.List()
  local buffer = nil
  for _, t in ipairs(inlines) do
    if t.t == 'Str' then
      if buffer == nil then
        buffer = t.text
      else
        buffer = buffer .. t.text
      end
    else
      if buffer ~= nil and buffer ~= '' then
        merged:insert(pandoc.Str(buffer))
        buffer = nil
      end
      merged:insert(t)
    end
  end
  if buffer ~= nil and buffer ~= '' then
    merged:insert(pandoc.Str(buffer))
  end
  return merged
end

local function process_inlines_for_pdf(inlines)
  local result = pandoc.List()
  local state = 'normal'
  local i = 1
  local function is_textlike(t)
    return t.t == 'Str' or t.t == 'Space' or t.t == 'SoftBreak' or t.t == 'LineBreak'
  end
  local function seg_to_string(seg)
    local buf = {}
    for _, t in ipairs(seg) do
      if t.t == 'Str' then buf[#buf+1] = t.text
      elseif t.t == 'Space' then buf[#buf+1] = ' '
      elseif t.t == 'SoftBreak' or t.t == 'LineBreak' then buf[#buf+1] = ' '
      end
    end
    return table.concat(buf)
  end
  while i <= #inlines do
    local inline = inlines[i]

    -- Handle substitution enclosed in braces: {~~orig~>new~~}
    if inline.t == 'Str' and inline.text == '{' and i + 2 <= #inlines then
      local mid = inlines[i + 1]
      local last = inlines[i + 2]
      if mid and mid.t == 'Strikeout' and last and last.t == 'Str' and last.text == '}' then
        local content = pandoc.utils.stringify(mid.content)
        local orig, new = content:match('^(.-)%s*~>%s*(.*)$')
        if orig and new then
          if critic_mode == 'edited' then
            if new ~= '' and include_for_mode('sub_new') then
              result:insert(pandoc.Str(new))
            end
          else
            if orig ~= '' and include_for_mode('sub_orig') then
              result:insert(pandoc.Str(orig))
            end
          end
          i = i + 3
          goto continue
        end
        -- Not a proper substitution; drop braces and pass content per mode
        if include_for_mode(state) then
          result:insert(mid)
        end
        i = i + 3
        goto continue
      end
    end

    if is_textlike(inline) then
      local seg = {}
      while i <= #inlines and is_textlike(inlines[i]) do
        seg[#seg + 1] = inlines[i]
        i = i + 1
      end
      -- step back one since outer loop will increment
      i = i - 1
      local text = seg_to_string(seg)
      local processed, new_state = process_text_segment(text, state)
      state = new_state
      if processed ~= '' then result:insert(pandoc.Str(processed)) end
    elseif inline.t == 'Strikeout' then
      if include_for_mode(state) then result:insert(inline) end
    else
      if include_for_mode(state) then result:insert(inline) end
    end
    i = i + 1
    ::continue::
  end
  return result
end

local function cirtiblock(blocks, k, v)
  local newblock = {}
  for _, t in pairs(blocks) do
    if t.text then
      local i, j = t.text:find(k, 1, true)
      if i then
        newblock[#newblock + 1] = pandoc.Str(t.text:sub(1, i - 1))
        newblock[#newblock + 1] = v
        newblock[#newblock + 1] = pandoc.Str(t.text:sub(j + 1, #t.text))
      else
        newblock[#newblock + 1] = t
      end
    else
      newblock[#newblock + 1] = t
    end
  end
  return newblock
end

function Str(el)
  if (critic_mode == 'markup') or FORMAT:match('latex') then
    local replaced = { el }
    for k, v in pairs(rules) do
      replaced = cirtiblock(replaced, k, v)
    end
    return replaced
  end
  -- for non-markup modes, Str is handled in Inlines processor
  return el
end

function Strikeout(strk)
  return strk.content
end

function Inlines(inlines)
  if critic_mode ~= 'markup' and not FORMAT:match('latex') then
    -- For PDF original/edited modes, strip or keep critic regions across tokens
    return process_inlines_for_pdf(inlines)
  end

  for i = #inlines - 1, 2, -1 do
    if inlines[i] and inlines[i].t == 'Strikeout' and inlines[i + 1] then
      if inlines[i + 1].t == 'Str' and inlines[i + 1].text == st_e then
        inlines[i + 1] = adde
      end
    end
    if inlines[i] and inlines[i].t == 'Strikeout' and inlines[i - 1] then
      if inlines[i - 1].t == 'Str' and inlines[i - 1].text == st_b then
        inlines[i - 1] = rm
      end
    end
  end
  return inlines
end

local function criticheader(meta)
  if meta['critic-mode'] then
    critic_mode = pandoc.utils.stringify(meta['critic-mode'])
  end

  -- Set up macros and rules for current format/mode
  setup_markup()
  if FORMAT:match 'html' then
    if critic_mode == 'markup' then
      quarto.doc.add_html_dependency({
        name = 'critic',
        scripts = { 'critic.min.js' },
        stylesheets = { 'critic.css' },
      })
      quarto.doc.include_text('after-body', scriptcode)
    end
  else
    -- latex header always includes mode-appropriate macro definitions
    if latexcode then
      quarto.doc.include_text('in-header', latexcode)
    end
  end
  return meta
end

return {
  { Meta = criticheader },
  { Inlines = Inlines },
  { Strikeout = Strikeout },
  { Str = Str },
}
