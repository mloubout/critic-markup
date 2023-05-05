
local maybesubs = false
local stk_end = false

add = pandoc.RawInline('html', "<ins>")
adde = pandoc.RawInline('html', "</ins>")

rm = pandoc.RawInline('html', "<del>")
rme = pandoc.RawInline('html', "</del>")
rmeadd = pandoc.RawInline('html', "</del><ins>")

mark = pandoc.RawInline('html', "<mark>")
marke = pandoc.RawInline('html', "</mark>")

comm = pandoc.RawInline('html', [[<span class="critic comment">]])
comme = pandoc.RawInline('html', "</span>")

ruless = {['{%+%+']=add, ['{\u{2013}']=rm, ['{==']=mark, ['{>>']=comm, ['{~~']=rm,
          ['%+%+}']=adde, ['\u{2013}}']=rme, ['==}']=marke, ['<<}']=comme, ['~~}']=rme, ['~>']=rmeadd}

-- Strikeout before/after
st_b = '{'
st_e = '}'

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

function cirtiblock(blocks, k, v)
  local newblock = {}
  for ti,t in pairs(blocks) do
    if t.text then
      i, j = t.text:find(k)
      if i then
        newblock[#newblock + 1] = pandoc.Str(t.text:sub(1, i-1))
        newblock[#newblock + 1] = v
        newblock[#newblock + 1] = pandoc.Str(t.text:sub(j+1, t.text:len()))
      else
        newblock[#newblock + 1] = t
      end
    else
      newblock[#newblock + 1] = t
    end
  end
  return newblock
end


if FORMAT:match 'html' then

  function Str (el)
    local replaced = {el}
    -- Check for standard substitutions
    for k,v in pairs(ruless) do
      replaced = cirtiblock(replaced, k, v)
    end
    return replaced
  end

  function Strikeout (strk)
    return strk.content
  end

  -- Check Inlines for Strikeout (~~) and remove brackets before/after for replacement
  function Inlines (inlines)
    for i = #inlines-1,2,-1 do
      if inlines[i] and inlines[i].t == 'Strikeout' and inlines[i+1] then
        if inlines[i+1].t == 'Str' then
          if inlines[i+1].text == st_e then
            inlines[i+1] = adde
          end
        end
      end
      if inlines[i] and inlines[i].t == 'Strikeout' and inlines[i-1] then
        if inlines[i-1].t == 'Str' then
          if inlines[i-1].text == st_b then
            inlines[i-1] = rm
          end
        end
      end
    end
    return inlines
  end
end

--- From the lightbox filter
local function add_header_includes(meta, blocks)

  local header_includes = pandoc.List(blocks)

  -- add any exisiting meta['header-includes']
  -- it could be a MetaList or a single String
  if meta['header-includes'] then
    if type(meta['header-includes']) == 'List' then
      header_includes:extend(meta['header-includes'])
    else
      header_includes:insert(meta['header-includes'])
    end
  end

  meta['header-includes'] = pandoc.MetaBlocks(header_includes)
  return meta
end


function criticheader (meta)
  quarto.doc.add_html_dependency({
    name = 'critic',
    scripts = {'critic.min.js'},
    stylesheets = {'critic.css'}
  })
  -- inject the rendering code
  quarto.doc.include_text("after-body", scriptcode)
end

-- All pass with Meta first
return {{Meta = criticheader}, {Inlines = Inlines}, {Strikeout = Strikeout}, {Str = Str}}
