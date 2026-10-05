# 500 Candy Pack: three glossy concept sketches (A bag, B jar, C chest).
import os
D=os.path.dirname(os.path.abspath(__file__))
DEFS='''<defs>
<radialGradient id="cream" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#FFFBEF"/><stop offset="1" stop-color="#F3D9B4"/></radialGradient>
<linearGradient id="pink" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF9AA6"/><stop offset="1" stop-color="#E8606F"/></linearGradient>
<linearGradient id="mint" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9EDC6"/><stop offset="1" stop-color="#86CF9C"/></linearGradient>
<linearGradient id="glass" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9F1F7"/><stop offset=".5" stop-color="#EEF9FC"/><stop offset="1" stop-color="#C6E6EF"/></linearGradient>
<linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2B36B"/><stop offset="1" stop-color="#D98A45"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE38A"/><stop offset="1" stop-color="#F1B93C"/></linearGradient>
</defs>'''
def svg(body): return f'<svg xmlns="http://www.w3.org/2000/svg" width="450" height="450" viewBox="0 0 450 450"><rect width="450" height="450" fill="#FFFFFF"/>{DEFS}<g stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'
def candy(x,y,r=0,s=1):
    return f'''<g transform="translate({x},{y}) rotate({r}) scale({s})">
<path d="M-24,0 L-52,-20 Q-58,0 -52,20 Z" fill="url(#pink)" stroke="#B9475A" stroke-width="4"/>
<path d="M24,0 L52,-20 Q58,0 52,20 Z" fill="url(#pink)" stroke="#B9475A" stroke-width="4"/>
<circle r="31" fill="url(#cream)" stroke="#B9475A" stroke-width="4"/>
<circle r="20" fill="none" stroke="#E8606F" stroke-width="6"/>
<path d="M0,-11 l3.5,7 8,1 -6,5.5 1.5,8 -7,-4 -7,4 1.5,-8 -6,-5.5 8,-1 Z" fill="#E8606F"/>
<ellipse cx="-12" cy="-16" rx="8" ry="4" fill="#FFFFFF" opacity=".9" transform="rotate(-30 -12 -16)"/></g>'''
HL='fill="#FFFFFF" opacity=".75"'

# A: plump striped candy pouch tied with a mint bow, candies overflowing.
A=svg(f'''
<path d="M120,220 C70,300 80,410 225,412 C370,410 380,300 330,220 Z" fill="url(#cream)" stroke="#C99A62" stroke-width="6"/>
<clipPath id="pa"><path d="M120,220 C70,300 80,410 225,412 C370,410 380,300 330,220 Z"/></clipPath>
<g clip-path="url(#pa)" fill="#FFB3BC"><path d="M130,200 l40,0 -30,230 -40,0Z"/><path d="M205,200 l40,0 0,230 -40,0Z"/><path d="M280,200 l40,0 30,230 -40,0Z"/></g>
<path d="M120,220 C70,300 80,410 225,412 C370,410 380,300 330,220 Z" fill="none" stroke="#C99A62" stroke-width="6"/>
{candy(160,190,-25)}{candy(290,188,25)}{candy(225,150,0,1.15)}
<path d="M118,222 C170,240 280,240 332,222 L326,248 C280,262 170,262 124,248 Z" fill="url(#mint)" stroke="#4F9A69" stroke-width="5"/>
<path d="M225,246 C190,212 160,226 170,252 C180,274 210,262 225,246 C240,262 270,274 280,252 C290,226 260,212 225,246Z" fill="url(#mint)" stroke="#4F9A69" stroke-width="5"/>
<circle cx="225" cy="248" r="12" fill="#86CF9C" stroke="#4F9A69" stroke-width="4"/>
<ellipse cx="128" cy="320" rx="12" ry="34" {HL}/>''')

# B: round glass candy jar with pink lid + bow, full of candies.
B=svg(f'''
<path d="M130,140 L320,140 L320,170 C390,200 395,380 330,410 L120,410 C55,380 60,200 130,170 Z" fill="url(#glass)" stroke="#7FB4C4" stroke-width="6"/>
<clipPath id="jb"><path d="M133,170 L317,170 C384,202 388,376 328,404 L122,404 C62,376 66,202 133,170 Z"/></clipPath>
<g clip-path="url(#jb)">{candy(150,372,-15,.8)}{candy(300,372,15,.8)}{candy(225,350,5,.9)}{candy(165,300,20,.8)}{candy(286,300,-20,.8)}{candy(226,258,0,.85)}</g>
<path d="M120,128 h210 a14,14 0 0 1 14,14 v14 a14,14 0 0 1 -14,14 h-210 a14,14 0 0 1 -14,-14 v-14 a14,14 0 0 1 14,-14Z" fill="url(#pink)" stroke="#B9475A" stroke-width="5"/>
<path d="M225,128 C196,92 162,104 172,128 Z M225,128 C254,92 288,104 278,128 Z" fill="url(#mint)" stroke="#4F9A69" stroke-width="5"/>
<circle cx="225" cy="124" r="11" fill="#86CF9C" stroke="#4F9A69" stroke-width="4"/>
<path d="M98,240 C90,290 94,340 112,380" stroke="#FFFFFF" stroke-width="12" fill="none" opacity=".8"/>
<path d="M134,138 h80" stroke="#FFFFFF" stroke-width="6" opacity=".7"/>''')

# C: small open treasure chest heaped with candies, gold trim.
C=svg(f'''
<path d="M110,140 C110,100 340,100 340,140 L340,200 L110,200 Z" fill="url(#wood)" stroke="#A8622A" stroke-width="6" transform="rotate(-8 225 200)"/>
{candy(170,200,-20)}{candy(285,196,18)}{candy(228,168,0,1.15)}{candy(130,232,-35,.9)}{candy(322,230,30,.9)}
<path d="M90,230 L360,230 L350,400 C350,410 342,414 334,414 L116,414 C108,414 100,410 100,400 Z" fill="url(#wood)" stroke="#A8622A" stroke-width="6"/>
<path d="M92,230 L358,230 L356,262 L94,262 Z" fill="url(#gold)" stroke="#C48A1E" stroke-width="5"/>
<path d="M140,262 v150 M310,262 v150" stroke="#F1B93C" stroke-width="14"/>
<path d="M200,280 h50 v44 a25,25 0 0 1 -50,0Z" fill="url(#gold)" stroke="#C48A1E" stroke-width="5"/>
<path d="M225,300 l4,8 9,1 -7,6 2,9 -8,-4 -8,4 2,-9 -7,-6 9,-1Z" fill="#E8606F"/>
<path d="M112,280 L118,390" stroke="#FFFFFF" stroke-width="8" opacity=".6"/>''')

for n,s in [('candy_pack_A_pouch',A),('candy_pack_B_jar',B),('candy_pack_C_chest',C)]:
    open(os.path.join(D,n+'.svg'),'w').write(s)
