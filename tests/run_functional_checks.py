"""Local functional checks; produces no manuscript performance measurements."""
from pathlib import Path
import subprocess,sys,tempfile
r=Path(__file__).resolve().parents[1]
for script in ['check_review_corrections.py','check_chacha_rounds.py']:
 subprocess.run([sys.executable,str(r/'tests'/script)],cwd=r,check=True)
with tempfile.TemporaryDirectory() as d:
 for top,files in [
  ('tb_pair_result_bank',['pair_result_bank.sv','tests/tb_pair_result_bank.sv']),
  ('tb_fpr_adder',['Fpr_adder.sv','tests/DW_fp_addsub_sim.sv','tests/tb_fpr_adder.sv']),
  ('tb_flt2int72',['flt2int72.sv','tests/tb_flt2int72.sv'])]:
  out=str(Path(d)/top)
  subprocess.run(['iverilog','-g2012','-s',top,'-o',out,*files],cwd=r,check=True)
  subprocess.run(['vvp',out],cwd=r,check=True)
subprocess.run(['verilator','--lint-only','-Wno-fatal','-Iinclude','--top-module','Bi_samplerz',*[p.name for p in r.glob('*.sv')],'tests/DW_fp_addsub_sim.sv'],cwd=r,check=True)
print('PASS functional checks; no full-signer, numerical-security, refill-continuity or PPA claim.')
