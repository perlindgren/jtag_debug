puts "jtag experiment"
connect
jtag targets  
jtag targets 2
set jseq [jtag sequence]
$jseq irshift -state IDLE -hex 6 23 
$jseq run