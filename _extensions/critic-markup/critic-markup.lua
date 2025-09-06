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

local latexcode = [[
\makeatletter
\@ifpackageloaded{pdfcomment}{
  \newcommand{\criticmarkupadd}[1]{\pdfmarkupcomment[markup=Highlight,color={0.838431 0.913725 0.734902}]{##1}{}}
  \newcommand{\criticmarkuprm}[1]{\pdfmarkupcomment[markup=Highlight,color={0.887059 0.673725 0.673725}]{##1}{}}
  \newcommand{\criticmarkupmark}[1]{\pdfmarkupcomment[markup=Highlight,color={1 0.99216 0.21961}]{##1}{}}
  \newcommand{\criticmarkupcomm}[1]{\pdfcomment[icon=Comment, color={0.89804 0.69020 0}]{##1}}
}{
  \newcommand{\criticmarkupadd}[1]{\{++{##1}++\}}
  \newcommand{\criticmarkuprm}[1]{\{-{}-{##1}-{}-\}}
  \newcommand{\criticmarkupmark}[1]{\{=={##1}==\}}
  \newcommand{\criticmarkupcomm}[1]{\{>>{##1}<<\}}
}
\makeatother
]]

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
  end

  rules = {
    ['{%+%+'] = add,
    ['{--'] = rm,
    ['{' .. en_dash] = rm,
    ['{=='] = mark,
    ['{>>'] = comm,
    ['{~~'] = rm,
    ['%+%+}'] = adde,
    ['--}'] = rme,
    [en_dash .. '}'] = rme,
    ['==}'] = marke,
    ['<<}'] = comme,
    ['~~}'] = rme,
    ['~>'] = rmeadd,
  }
end

local function cirtiblock(blocks, k, v)
  local newblock = {}
  for _, t in pairs(blocks) do
    if t.text then
      local i, j = t.text:find(k)
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
  if critic_mode == 'markup' then
    local replaced = { el }
    for k, v in pairs(rules) do
      replaced = cirtiblock(replaced, k, v)
    end
    return replaced
  end

  local text = el.text

  -- additions
  text = text:gsub('{%+%+(.-)%+%+}', function(addition)
    if critic_mode == 'edited' then
      return addition
    else
      return ''
    end
  end)

  -- deletions (ASCII and en dash versions)
  local function del_handler(deleted)
    if critic_mode == 'edited' then
      return ''
    else
      return deleted
    end
  end

  text = text:gsub('{%-%-(.-)%-%-}', del_handler)
  text = text:gsub('{' .. en_dash .. '(.-)' .. en_dash .. '}', del_handler)

  -- substitutions
  text = text:gsub('{~~(.-)~>(.-)~~}', function(orig, new)
    if critic_mode == 'edited' then
      return new
    else
      return orig
    end
  end)

  -- highlights and comments
  text = text:gsub('{==(.-)==}', '%1')
  text = text:gsub('{>>.-<<}', '')

  return pandoc.Str(text)
end

function Strikeout(strk)
  return strk.content
end

function Inlines(inlines)
  if critic_mode ~= 'markup' then
    return inlines
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

  if critic_mode == 'markup' then
    setup_markup()
    if FORMAT:match 'html' then
      quarto.doc.add_html_dependency({
        name = 'critic',
        scripts = { 'critic.min.js' },
        stylesheets = { 'critic.css' },
      })
      quarto.doc.include_text('after-body', scriptcode)
    else
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

