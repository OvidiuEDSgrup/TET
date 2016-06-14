select p.Locatie,* -- delete p
from pozdoc p where p.Factura like 'CJ980819'

declare @p2 xml
set @p2=convert(xml,N'<parametri subunitate="1" tip="BK" numar="CJ980819" data="08/19/2014" explicatii="" termen="08/19/2014" dengestiune="CJ SHOWROOM  CLUJ" gestiune="211.CJ" dentert="1710605126190 - MOLDOVAN AUREL" factura="" tert="1710605126190" contractcor="" punctlivrare="" denpunctlivrare="" denlm="CLUJ3" lm="1VZ_CJ_03" dengestprim="CJ MARFA  INSTALATORI TEMPORAR" gestprim="700.CJ" valuta="" curs="0.0000" valoare="1512.00" valtva="362.88" valtotala="1874.88" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="8" discount="0.0000000e+000" comspec="0" operat="08/19/2014" stare="1" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="1-Facturabil" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="10.00" info6="" culoare="#0000FF" _nemodificabil="1" numedelegat="C" numarCI="" serieCI="" eliberatCI="" nrmijtransp="D" observatii="C" o_numedelegat="C" o_observatii="C" update="1" nrmijltransp="e" numardoc="" datadoc="08/19/2014" aviznefacturat="0" tipMacheta="D" codMeniu="CO" TipDetaliere="BK" subtip="GD"><row subunitate="1" tip="BK" subtip="BK" numar="CJ980819" data="2014-08-19T00:00:00" cod="17PK-2005" dencod="17PK-2005 - HE-Racord drept 20x3/4&quot;&quot; T, pr" gestiune="211.CJ" cantitate="4.00000" valuta="" termene="08/19/2014" termen="08/19/2014" Tpret="16.0000" tert="1710605126190" Tcantitate="4.00000" Tcant_realizata="0.00000" um1="BUC" cantitateum1="4.00000" um2="" coefconvum2="0.00000" cantitateum2="0.00000" um3="" coefconvum3="0.00000" cantitateum3="0.00000" pret="16.00000" cant_transferata="0.0000" discount="10.00000" cotatva="24.00" punctlivrare="700.CJ" modplata="" denumire="HE-Racord drept 20x3/4&quot;&quot; T, press" dengestiune="CJ SHOWROOM  CLUJ" tipgestiune="C" dentert="MOLDOVAN AUREL" cant_realizata="0.00000" cant_aprobata="4.00000" termen_poz="08/19/2014" explicatii="" denspecif="" numarpozitie="8" lot="" dataexpirarii="01/01/1901" obiect="" denobiect="" info1="0.000000000000000e+000" info2="" info3="0.000000000000000e+000" info4="" info5="" info6="Jan  1 190" info7="Jan  1 190" info8="0.00000" info9="0.00000" info10="0.00000" info11="0.00000" info12="" info13="" info14="" info15="" info16="" info17="" Tachitat="0.00" Tfacturat="0.00" codsisursa="17PK-2005 - HE-Racord drept 20x3/4&quot;&quot; T, press&#x0A;"/></parametri>')
exec yso_wOPGenTEsauAPdinBK @sesiune='EDC844C6E3520',@parXML=@p2
/*
(case			when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
					then pd.cantitate
				when pd.nrordmin=s1.nrord --prima linie de pe stoc
					then pd.cantitate-(pd.cumulat-s1.stoctotal)
				when pd.nrordmax=s1.nrord --ultima linie de pe stoc
					then (pd.cumulat+s1.stoc-s1.stoctotal)
			  else s1.stoc
			end) as cantitate
*/