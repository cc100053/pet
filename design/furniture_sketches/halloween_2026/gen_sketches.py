import os
D=os.path.dirname(os.path.abspath(__file__))
DEFS='''<defs>
<filter id="paint" x="-8%" y="-8%" width="116%" height="116%">
 <feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="2" seed="4" result="warp"/>
 <feDisplacementMap in="SourceGraphic" in2="warp" scale="5" xChannelSelector="R" yChannelSelector="G" result="w"/>
 <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" seed="9" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0.7 0 0 0 -0.28" result="na"/>
 <feComposite in="na" in2="w" operator="in" result="grain"/>
 <feMerge><feMergeNode in="w"/><feMergeNode in="grain"/></feMerge>
</filter>
<radialGradient id="glow"><stop offset="0" stop-color="#FFF6C8" stop-opacity=".95"/><stop offset="1" stop-color="#FFD66E" stop-opacity="0"/></radialGradient>
</defs>'''
def svg(body): return f'<svg xmlns="http://www.w3.org/2000/svg" width="450" height="450" viewBox="0 0 450 450">{DEFS}<g filter="url(#paint)" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'

# 1. Pumpkin lantern
pumpkin=svg('''
<path d="M236,150 C246,128 262,118 282,112" fill="none" stroke="#95B06E" stroke-width="6"/>
<path d="M282,112 C290,88 318,78 338,86 C332,108 306,118 282,112 Z" fill="#A8C585" stroke="#7E9B5E" stroke-width="4"/>
<path d="M288,110 C302,102 316,94 330,90" stroke="#7E9B5E" stroke-width="3" fill="none"/>
<path d="M212,158 C212,130 208,108 200,92 C212,86 226,88 232,96 C236,114 238,136 240,158 Z" fill="#7F8F52" stroke="#5C6B3A" stroke-width="5"/>
<path d="M214,104 C218,120 220,136 220,150" stroke="#A3B27A" stroke-width="3" fill="none"/>
<ellipse cx="128" cy="285" rx="82" ry="112" fill="#E5864A" stroke="#C4632F" stroke-width="5"/>
<ellipse cx="322" cy="285" rx="82" ry="112" fill="#E5864A" stroke="#C4632F" stroke-width="5"/>
<ellipse cx="172" cy="280" rx="88" ry="128" fill="#EE9654" stroke="#C4632F" stroke-width="5"/>
<ellipse cx="278" cy="280" rx="88" ry="128" fill="#EE9654" stroke="#C4632F" stroke-width="5"/>
<ellipse cx="225" cy="278" rx="80" ry="134" fill="#F4A560" stroke="#C4632F" stroke-width="5"/>
<g stroke="#FFD7A8" stroke-width="4" fill="none" opacity=".85">
 <path d="M92,230 C86,256 86,282 90,306"/><path d="M142,196 C132,226 130,258 134,290"/>
 <path d="M200,180 C192,206 190,232 192,256"/><path d="M104,330 C108,344 112,352 118,360"/>
</g>
<g stroke="#C4632F" stroke-width="3" fill="none" opacity=".6">
 <path d="M372,250 L380,256"/><path d="M366,300 L376,304"/><path d="M322,356 L330,366"/><path d="M270,380 L276,392"/>
</g>
<ellipse cx="225" cy="290" rx="120" ry="90" fill="url(#glow)" opacity=".55"/>
<path d="M158,262 C166,230 186,222 196,258 C184,266 170,268 158,262 Z" fill="#FFE08A" stroke="#B85A2A" stroke-width="5"/>
<path d="M254,258 C264,222 284,230 292,262 C280,268 266,266 254,258 Z" fill="#FFE08A" stroke="#B85A2A" stroke-width="5"/>
<path d="M160,300 C188,318 262,318 290,300 C284,340 256,360 225,360 C194,360 166,340 160,300 Z" fill="#FFE08A" stroke="#B85A2A" stroke-width="5"/>
<path d="M214,313 L236,313 L232,330 L218,330 Z" fill="#F4A560" stroke="#B85A2A" stroke-width="4"/>
<path d="M180,318 C200,344 250,344 270,318" fill="none" stroke="#FFF6D0" stroke-width="5" opacity=".9"/>
<ellipse cx="140" cy="300" rx="16" ry="10" fill="#F28C8C" opacity=".55"/>
<ellipse cx="310" cy="300" rx="16" ry="10" fill="#F28C8C" opacity=".55"/>
<path d="M58,250 C54,280 56,320 72,352" stroke="#FFFFFF" stroke-width="6" fill="none" opacity=".7"/>
''')

# 2. Candy cauldron
def wrap(x,y,r,fill,edge):
    return f'''<g transform="translate({x},{y}) rotate({r})">
<path d="M-16,0 L-40,-15 L-35,0 L-40,15 Z" fill="{fill}" stroke="{edge}" stroke-width="4"/>
<path d="M16,0 L40,-15 L35,0 L40,15 Z" fill="{fill}" stroke="{edge}" stroke-width="4"/>
<circle r="20" fill="{fill}" stroke="{edge}" stroke-width="4"/>
<path d="M-8,-10 C-2,-14 6,-12 10,-6" stroke="#FFFFFF" stroke-width="4" fill="none" opacity=".8"/></g>'''
cauldron=svg(f'''
<path d="M140,370 L128,414 L154,414 L168,372 Z" fill="#43395F" stroke="#2F2748" stroke-width="5"/>
<path d="M310,370 L322,414 L296,414 L282,372 Z" fill="#43395F" stroke="#2F2748" stroke-width="5"/>
<path d="M92,222 C80,310 118,392 225,394 C332,392 370,310 358,222 Z" fill="#5E5280" stroke="#3E345E" stroke-width="5"/>
<ellipse cx="225" cy="222" rx="136" ry="32" fill="#3E345E"/>
<path d="M300,210 L322,92" stroke="#FFF4E6" stroke-width="10"/>
<path d="M300,210 L322,92" stroke="#E6D5C3" stroke-width="3"/>
<circle cx="324" cy="86" r="34" fill="#F7B8CC" stroke="#D98AA3" stroke-width="5"/>
<clipPath id="pop"><circle cx="324" cy="86" r="31"/></clipPath><path clip-path="url(#pop)" d="M324,86 m0,-4 a4,4 0 1,1 -4,6 a10,10 0 1,1 14,-12 a18,18 0 1,1 -24,20 a26,26 0 1,1 34,-28" fill="none" stroke="#FFFFFF" stroke-width="6"/>
<path d="M120,222 C130,180 170,158 225,152 C282,158 326,182 334,222 Z" fill="#F3E3C8" stroke="#D8C2A0" stroke-width="4"/>
<g transform="translate(206,150)">
 <path d="M-28,40 L-28,0 C-28,-22 -14,-36 0,-36 C14,-36 28,-22 28,0 L28,40 C22,34 18,34 14,40 C10,34 4,34 0,40 C-4,34 -10,34 -14,40 C-18,34 -24,34 -28,40 Z" fill="#FFFFFF" stroke="#BFC6E6" stroke-width="5"/>
 <ellipse cx="-10" cy="-4" rx="4" ry="6" fill="#4A4063"/><ellipse cx="10" cy="-4" rx="4" ry="6" fill="#4A4063"/>
 <path d="M-5,8 C-2,12 2,12 5,8" stroke="#4A4063" stroke-width="3" fill="none"/>
 <ellipse cx="-18" cy="6" rx="6" ry="4" fill="#F7B8CC" opacity=".8"/><ellipse cx="18" cy="6" rx="6" ry="4" fill="#F7B8CC" opacity=".8"/>
</g>
{wrap(262,196,14,"#A8D8B9","#6FAE88")}
{wrap(196,210,-6,"#F7DC8A","#D4B252")}
{wrap(312,216,-24,"#C9B6EA","#9A84C6")}
<path d="M89,222 C92,248 358,248 361,222" fill="none" stroke="#7A6CA0" stroke-width="16"/>
<path d="M96,226 C120,244 180,250 225,250" fill="none" stroke="#A89BCB" stroke-width="4" opacity=".8"/>
<g stroke="#8C7FB4" stroke-width="5" fill="none" opacity=".75">
 <path d="M118,280 C120,316 136,346 160,364"/><path d="M140,276 C142,300 150,320 162,334"/>
</g>
<g transform="translate(262,318)" fill="#F4A560" stroke="#C4632F" stroke-width="3">
 <path d="M-26,0 C-22,-12 -12,-14 -6,-6 C-4,-12 4,-12 6,-6 C12,-14 22,-12 26,0 C18,-4 12,2 8,8 C4,4 -4,4 -8,8 C-12,2 -18,-4 -26,0 Z"/>
</g>
<path d="M96,236 C88,290 104,346 146,378" stroke="#FFFFFF" stroke-width="5" fill="none" opacity=".45"/>
''')

# 3. Bat-wing armchair
wing='<path d="M140,150 C100,112 58,100 20,112 C36,138 40,164 34,194 C56,182 78,186 86,208 C100,194 120,196 130,218 C136,210 144,208 150,214 Z" fill="#6B5391" stroke="#4B3870" stroke-width="5"/><path d="M130,150 C100,132 70,126 44,128 M112,168 C96,176 84,184 78,196 M128,178 C124,194 124,204 128,212" stroke="#8D78B3" stroke-width="3" fill="none"/>'
chair=svg(f'''
{wing}<g transform="translate(450,0) scale(-1,1)">{wing}</g>
<path d="M150,108 L160,52 L196,90 Z" fill="#7C60A0" stroke="#553F7C" stroke-width="5"/>
<path d="M300,108 L290,52 L254,90 Z" fill="#7C60A0" stroke="#553F7C" stroke-width="5"/>
<path d="M162,98 L165,70 L182,90 Z M288,98 L285,70 L268,90 Z" fill="#E9A8C4"/>
<path d="M130,300 L130,150 C130,98 174,80 225,80 C276,80 320,98 320,150 L320,300 Z" fill="#8A6BAE" stroke="#5E4583" stroke-width="5"/>
<g fill="#E8DDF5">
 <circle cx="180" cy="130" r="5"/><circle cx="225" cy="118" r="5"/><circle cx="270" cy="130" r="5"/>
 <circle cx="160" cy="180" r="5"/><circle cx="290" cy="180" r="5"/><circle cx="225" cy="170" r="5"/>
</g>
<g stroke="#A68CC7" stroke-width="3" fill="none" opacity=".9">
 <path d="M180,130 L225,170 L270,130 M160,180 L225,170 L290,180 M225,118 L225,170"/>
</g>
<path d="M148,104 C140,120 138,150 140,190" stroke="#FFFFFF" stroke-width="5" fill="none" opacity=".55"/>
<rect x="140" y="262" width="170" height="58" rx="24" fill="#B397D1" stroke="#7A5C9E" stroke-width="5"/>
<mask id="moon"><rect width="450" height="450" fill="#fff"/><circle cx="262" cy="232" r="42" fill="#000"/></mask>
<g mask="url(#moon)"><circle cx="226" cy="246" r="50" fill="#F7DC8A" stroke="#D4B252" stroke-width="5"/></g>
<path d="M198,246 C202,252 210,252 214,246" stroke="#8A6A2E" stroke-width="3" fill="none"/>
<ellipse cx="206" cy="262" rx="7" ry="4" fill="#F4A6B8" opacity=".85"/>
<path d="M190,222 C184,238 186,258 194,272" stroke="#FFFBE6" stroke-width="4" fill="none"/>
<rect x="94" y="212" width="70" height="140" rx="35" fill="#7C60A0" stroke="#553F7C" stroke-width="5"/>
<rect x="286" y="212" width="70" height="140" rx="35" fill="#7C60A0" stroke="#553F7C" stroke-width="5"/>
<path d="M110,232 C106,262 106,296 110,326" stroke="#A68CC7" stroke-width="5" fill="none"/>
<path d="M340,232 C344,262 344,296 340,326" stroke="#6A5090" stroke-width="5" fill="none"/>
<rect x="104" y="306" width="242" height="72" rx="22" fill="#73579A" stroke="#553F7C" stroke-width="5"/>
<path d="M118,352 C140,340 160,364 182,352 C204,340 224,364 246,352 C268,340 288,364 310,352 C320,346 328,348 334,352" stroke="#E9A8C4" stroke-width="5" fill="none"/>
<path d="M138,374 C132,394 122,402 112,408 C126,416 146,410 152,396 L158,374 Z" fill="#EEC859" stroke="#C9A031" stroke-width="4"/>
<path d="M312,374 C318,394 328,402 338,408 C324,416 304,410 298,396 L292,374 Z" fill="#EEC859" stroke="#C9A031" stroke-width="4"/>
''')
for n,s in [("pumpkin_lantern",pumpkin),("candy_cauldron",cauldron),("bat_armchair",chair)]:
    open(f"{D}/{n}.svg","w").write(s)
