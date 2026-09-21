"""Check unmodified round RTL against RFC 8439 arithmetic; not the refill wrapper."""
from pathlib import Path
import random,re,subprocess,tempfile
root=Path(__file__).resolve().parents[1]
s=(root/'chacha20.sv').read_text()
mods='\n'.join(re.search(r'module '+n+r'\b.*?endmodule',s,re.S).group() for n in ['chacha20_round_2stage','qround'])
mods='typedef logic [31:0] vect_t;\ntypedef logic [15:0][31:0] row_data_pack_t;\n'+mods
mask=(1<<32)-1
def rot(x,n):return ((x<<n)|(x>>(32-n)))&mask
def qr(a,b,c,d):
 a=(a+b)&mask;d=rot(d^a,16);c=(c+d)&mask;b=rot(b^c,12)
 a=(a+b)&mask;d=rot(d^a,8);c=(c+d)&mask;b=rot(b^c,7)
 return a,b,c,d
def double(v):
 v=v.copy()
 for ix in [(0,4,8,12),(1,5,9,13),(2,6,10,14),(3,7,11,15),(0,5,10,15),(1,6,11,12),(2,7,8,13),(3,4,9,14)]:
  out=qr(*(v[i] for i in ix))
  for i,x in zip(ix,out):v[i]=x
 return v
def packed(v):return ''.join(f'{x:08x}' for x in reversed(v))
r=random.Random(8439);cases=[[0]*16,list(range(16)),[mask]*16]+[[r.getrandbits(32) for _ in range(16)] for _ in range(29)]
body='''module tb;logic clk=0;row_data_pack_t data_i,data_o;
chacha20_round_2stage dut(.*);
logic [31:0] a,b,c,d,ao,bo,co,do_;qround q(a,b,c,d,ao,bo,co,do_);
initial begin
a=32'h11111111;b=32'h01020304;c=32'h9b8d6f43;d=32'h01234567;#1;
if({ao,bo,co,do_}!==128'hea2a92f4cb1cf8ce4581472e5881c4bb)$fatal(1,"RFC quarter round");
'''
for i,v in enumerate(cases):
 body+=f"data_i=512'h{packed(v)};#2;clk=1;#1;clk=0;#1;if(data_o!==512'h{packed(double(v))})$fatal(1,\"double round {i}\");\n"
body+='$display("PASS ChaCha round RTL: RFC quarter-round vector and 32 double-round states");$finish;end endmodule\n'
with tempfile.TemporaryDirectory() as d:
 p=Path(d);(p/'tb.sv').write_text(mods+'\n'+body)
 subprocess.run(['iverilog','-g2012','-s','tb','-o',str(p/'sim'),str(p/'tb.sv')],check=True)
 subprocess.run(['vvp',str(p/'sim')],check=True)
