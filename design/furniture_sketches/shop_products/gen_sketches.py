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
</defs>'''
def svg(body): return f'<svg xmlns="http://www.w3.org/2000/svg" width="450" height="450" viewBox="0 0 450 450">{DEFS}<g filter="url(#paint)" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'

def paw(x,y,s,fill):
    return f'''<g transform="translate({x},{y}) scale({s})" fill="{fill}">
<ellipse cx="0" cy="10" rx="16" ry="13"/><ellipse cx="-18" cy="-8" rx="6" ry="8"/><ellipse cx="-6" cy="-17" rx="6" ry="8"/>
<ellipse cx="6" cy="-17" rx="6" ry="8"/><ellipse cx="18" cy="-8" rx="6" ry="8"/></g>'''

# 1. Pet ticket: cream ticket, notched sides, sage stub behind a dashed perforation, paw stamp.
ticket=svg(f'''<g transform="rotate(-10 225 225)">
<path d="M58,140 H392 V196 A26,26 0 0 0 392,254 V310 H58 V254 A26,26 0 0 0 58,196 Z" fill="#F3E6CF" stroke="#C9A97A" stroke-width="6"/>
<path d="M300,140 H392 V196 A26,26 0 0 0 392,254 V310 H300 Z" fill="#9DB59C" stroke="#6F8C6E" stroke-width="6"/>
<path d="M300,152 V298" stroke="#C9A97A" stroke-width="5" stroke-dasharray="10 12"/>
<rect x="82" y="164" width="196" height="122" rx="14" fill="none" stroke="#D2935A" stroke-width="5"/>
<circle cx="180" cy="225" r="44" fill="#F7C8B4" stroke="#D2935A" stroke-width="5"/>
{paw(180,226,1.25,"#D2935A")}
<path d="M346,196 l7,14 15,2 -11,11 3,15 -14,-7 -14,7 3,-15 -11,-11 15,-2 Z" fill="#F3E6CF" stroke="#6F8C6E" stroke-width="4"/>
<path d="M90,152 H200" stroke="#FFFFFF" stroke-width="5" opacity=".7"/>
<g stroke="#C9A97A" stroke-width="3" opacity=".6"><path d="M96,296 l10,-8"/><path d="M116,296 l10,-8"/></g>
</g>''')

# 2. 500 candy pack: pink-cream striped paper bag tied with a sage ribbon, star candies spilling over the top and one at the front.
def candy(x,y,r,s=1):
    return f'''<g transform="translate({x},{y}) rotate({r}) scale({s})">
<path d="M-24,0 L-50,-18 L-44,0 L-50,18 Z" fill="#EE8A96" stroke="#C25C6C" stroke-width="4"/>
<path d="M24,0 L50,-18 L44,0 L50,18 Z" fill="#EE8A96" stroke="#C25C6C" stroke-width="4"/>
<circle r="30" fill="#F8E7CE" stroke="#C25C6C" stroke-width="4"/>
<circle r="19" fill="none" stroke="#E46A7A" stroke-width="6"/>
<path d="M0,-11 l3.5,7 8,1 -6,5.5 1.5,8 -7,-4 -7,4 1.5,-8 -6,-5.5 8,-1 Z" fill="#E46A7A"/></g>'''
pack=svg(f'''
<path d="M110,200 L340,200 L362,404 C362,412 356,416 348,416 L102,416 C94,416 88,412 88,404 Z" fill="#F8E7CE" stroke="#C9A97A" stroke-width="6"/>
<clipPath id="bag"><path d="M110,200 L340,200 L362,404 L88,404 Z"/></clipPath>
<g clip-path="url(#bag)" fill="#F4B6BE">
 <path d="M120,200 h36 l-14,216 h-36 Z"/><path d="M196,200 h36 l0,216 h-36 Z"/><path d="M272,200 h36 l16,216 h-36 Z"/>
</g>
<path d="M110,200 L340,200 L362,404 C362,412 356,416 348,416 L102,416 C94,416 88,412 88,404 Z" fill="none" stroke="#C9A97A" stroke-width="6"/>
{candy(225,168,0,1.1)}{candy(158,196,-20)}{candy(292,194,22)}
<path d="M104,206 C150,222 300,222 346,206 L342,232 C300,248 150,248 108,232 Z" fill="#9DB59C" stroke="#6F8C6E" stroke-width="5"/>
<path d="M225,226 C196,196 168,206 176,230 C184,250 210,240 225,226 C240,240 266,250 274,230 C282,206 254,196 225,226 Z" fill="#9DB59C" stroke="#6F8C6E" stroke-width="5"/>
<circle cx="225" cy="228" r="11" fill="#7FA07E" stroke="#6F8C6E" stroke-width="4"/>
{candy(226,330,-8,1.25)}
<path d="M112,262 L102,390" stroke="#FFFFFF" stroke-width="6" opacity=".6"/>
''')

for name,s in [('pet_ticket',ticket),('candy_pack_500',pack)]:
    open(os.path.join(D,name+'.svg'),'w').write(s)
