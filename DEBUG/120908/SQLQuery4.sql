declare @p2 xml
set @p2=convert(xml,
N'<row subunitate="1" tip="AP" tert="RO4574561" numar="0       " data="09/08/2012" categpret="1" lm="1MKT19   " gestiune="211" contract="9810312">
  <row pvaluta="19.2" valuta="   " curs="0" lm="1MKT19   " cod="08013012" cantitate="18" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="19.2" valuta="   " curs="0" lm="1MKT19   " cod="08013012" cantitate="7" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="7.43" valuta="   " curs="0" lm="1MKT19   " cod="1-1604A" cantitate="34" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="16.44" valuta="   " curs="0" lm="1MKT19   " cod="1-2606A" cantitate="2" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="16.44" valuta="   " curs="0" lm="1MKT19   " cod="1-2606A" cantitate="8" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="8.48" valuta="   " curs="0" lm="1MKT19   " cod="100-ISO4-16-BL" cantitate="100" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="8.48" valuta="   " curs="0" lm="1MKT19   " cod="100-ISO4-16-RO" cantitate="100" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="1.73" valuta="   " curs="0" lm="1MKT19   " cod="10410000" cantitate="1" contract="9810312" discount="0.0000000e+000"/>
  <row pvaluta="49.23" valuta="   " curs="0" lm="1MKT19   " cod="10410005" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="21.95" valuta="   " curs="0" lm="1MKT19   " cod="25-ISO4-26-BL" cantitate="25" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="21.95" valuta="   " curs="0" lm="1MKT19   " cod="25-ISO4-26-RO" cantitate="25" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="18.62" valuta="   " curs="0" lm="1MKT19   " cod="8-161616A" cantitate="2" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="110.3" valuta="   " curs="0" lm="1MKT19   " cod="BST-C060408" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="110.3" valuta="   " curs="0" lm="1MKT19   " cod="BST-C060408" cantitate="2" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="149.8" valuta="   " curs="0" lm="1MKT19   " cod="BST-C060410" cantitate="1" contract="9810312" discount="0.0000000e+000"/>
  <row pvaluta="11.65" valuta="   " curs="0" lm="1MKT19   " cod="EFC-CMF11" cantitate="2" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="4.86" valuta="   " curs="0" lm="1MKT19   " cod="EFC-DF11" cantitate="2" contract="9810312" discount="0.0000000e+000"/>
  <row pvaluta="5.35" valuta="   " curs="0" lm="1MKT19   " cod="EFC-N1134" cantitate="2" contract="9810312" discount="0.0000000e+000"/>
  <row pvaluta="14.5" valuta="   " curs="0" lm="1MKT19   " cod="EFC-T11" cantitate="4" contract="9810312" discount="0.0000000e+000"/>
  <row pvaluta="7.84" valuta="   " curs="0" lm="1MKT19   " cod="EK 16" cantitate="15" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="18.69" valuta="   " curs="0" lm="1MKT19   " cod="H-0212" cantitate="2" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="18.69" valuta="   " curs="0" lm="1MKT19   " cod="H-0212" cantitate="4" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="41.54" valuta="   " curs="0" lm="1MKT19   " cod="RB-HMF11" cantitate="2" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="277.8" valuta="   " curs="0" lm="1MKT19   " cod="UFH-BTM0606-M" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="477.47" valuta="   " curs="0" lm="1MKT19   " cod="UFH-CAB-I800" cantitate="2" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="107.98" valuta="   " curs="0" lm="1MKT19   " cod="UFH-ESK060303" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="107.98" valuta="   " curs="0" lm="1MKT19   " cod="UFH-ESK060303" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="77.49" valuta="   " curs="0" lm="1MKT19   " cod="VB-060502-B" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="111.17" valuta="   " curs="0" lm="1MKT19   " cod="VB-060503-B" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="111.17" valuta="   " curs="0" lm="1MKT19   " cod="VB-060503-B" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
  <row pvaluta="111.17" valuta="   " curs="0" lm="1MKT19   " cod="VB-060503-R" cantitate="1" contract="9810312" discount="1.5000000e+001"/>
</row>')
exec wScriuPozdoc @sesiune=null,@parxml=@p2