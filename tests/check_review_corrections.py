"""Focused checks only: no full sampler simulation or conformance claim.
Run with --original to demonstrate that the published version fails.
"""
from pathlib import Path
import re, subprocess, sys, tempfile
root=Path(__file__).resolve().parents[1]
def source(name):
    if '--original' in sys.argv:
        return subprocess.check_output(['git','show','HEAD:'+name],cwd=root,text=True)
    return (root/name).read_text()
top=source('Bi_samplerz.sv'); base=source('basesampler.sv')
expected=[3024686241123004913666,1564742784480091954050,636254429462080897535,
199560484645026482916,47667343854657281903,8595902006365044063,
1163297957344668388,117656387352093658,8867391802663976,496969357462633,
20680885154299,638331848991,14602316184,247426747,3104126,28824,198,1]
actual=[int(x) for x in re.findall(r"72'd(\d+)",base)]
errors=[]
if actual!=expected: errors.append('RCDT constants differ from Falcon specification table 3.1')
points={0,(1<<72)-1}
for t in expected+actual:
    points.update(x for x in (t-1,t,t+1) if 0<=x<(1<<72))
for u in sorted(points):
    c=[int(u<t) for t in actual]+[0]
    selected=[i for i,v in enumerate([1-c[0]]+[c[i]*(1-c[i+1]) for i in range(18)]) if v]
    wanted=sum(u<t for t in expected)
    if selected!=[wanted]: errors.append(f'Base selector at {u}: {selected}; expected {wanted}'); break
# Compile the literal connection and direction expressions taken from the source.
connection=re.search(r'base_rdm144 (?:=|<=) (\{[^;]+\});',top).group(1)
direction=re.search(r'next_state = (\([^;]+\)\? SWITCHL : SWITCHR);',top).group(1)
body='''module focused_tb;
reg [79:0] refill_rdm10_l,refill_rdm10_r;
wire [143:0] base_rdm144 = CONNECTION;
localparam [7:0] SWITCHL=8'h10,SWITCHR=8'h20;
reg assist_l,cmp_rlt_l,cmp_rlt_r;
wire round_accept_r=cmp_rlt_r;
wire [7:0] next_state=DIRECTION;
integer lane,k;
initial begin
assist_l=0;cmp_rlt_l=0;cmp_rlt_r=0;
for(lane=0;lane<2;lane=lane+1) begin
 for(k=0;k<80;k=k+1) begin
  refill_rdm10_l=0;refill_rdm10_r=0;
  if(lane==0) refill_rdm10_l[k]=1; else refill_rdm10_r[k]=1;
  #1;
  if(base_rdm144[143:72] !== (refill_rdm10_l >> 8)) $fatal(1,"left magnitude allocation");
  if(base_rdm144[71:0] !== (refill_rdm10_r >> 8)) $fatal(1,"right magnitude allocation");
 end
end
cmp_rlt_l=0;cmp_rlt_r=1;#1;
if(next_state!==SWITCHL) $fatal(1,"right accepted: right must help left");
cmp_rlt_l=1;cmp_rlt_r=0;#1;
if(next_state!==SWITCHR) $fatal(1,"left accepted: left must help right");
$display("PASS: 160 bit-routing cases and both asymmetric direction expressions");
$finish;
end
endmodule
'''.replace('CONNECTION',connection).replace('DIRECTION',direction)
with tempfile.TemporaryDirectory() as d:
 p=Path(d);(p/'tb.sv').write_text(body)
 subprocess.run(['iverilog','-g2012','-s','focused_tb','-o',str(p/'sim'),str(p/'tb.sv')],check=True)
 result=subprocess.run(['vvp',str(p/'sim')],text=True,capture_output=True)
 print(result.stdout.strip())
 if result.returncode: errors.append('Extracted-expression RTL simulation failed')
if errors:
 print('FAIL:\n'+'\n'.join(errors));sys.exit(1)
print(f'PASS: all 18 RCDT constants and {len(points)} threshold boundary points')
print('LIMIT: this focused checker alone does not cover result retention, signed output, PRNG, arithmetic, timing or PPA; see the other directed tests.')
