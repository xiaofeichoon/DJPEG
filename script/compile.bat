mkdir xst
mkdir xst_temp
xst -ifn ../config/aq_djpeg.xst -ofn aq_djpeg.syr
ngdbuild -dd _ngo -nt timestamp -uc ../config/aq_djpeg.ucf -p xc3s500e-fg320-4 aq_djpeg.ngc aq_djpeg.ngd
map -p xc3s500e-fg320-4 -cm speed -ir off -pr b -c 100 -o aq_djpeg_map.ncd aq_djpeg.ngd aq_djpeg.pcf
par -w -ol high -t 1 aq_djpeg_map.ncd aq_djpeg.ncd aq_djpeg.pcf
bitgen -f ../config/aq_djpeg.ut aq_djpeg.ncd
