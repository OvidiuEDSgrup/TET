/*
Am incercat sa reprodus descarcare bonului trimis dinspre PVria sub frma de apeluri proceduri cu parametru xml pt a nu mai fi nevoie sa va
trimit alt backup ca sa nu va incurc si pt ca dureaza prea mult copierea lui desi e comprimat implicit de sql 2008r2 (chiar si facut rar e tot asa)
*/
--aici am pus inapoi validarea stocului negativ care era scoasa pe backup-ul facut ieri si trimis la dvs pt a putea da niste refaceri
update par set Val_logica=0 where par.Parametru like 'FARAVSTN'
go

--aici am luat cu profiler exact ce a trimis PVria la SQL, la care am adaugat atributul GESTPV="212.1" atat cat avea utilizatorul magazin_NT
declare @p2 xml
set @p2=convert(xml,N'<date>
  <document GESTPV="212.1" aplicatie="PV" tip="PV" casamarcat="1" data="10/05/2012" inXML="0" UID="96DC6297-3DFB-EA11-13FC-2FF06BBF41FF" categoriePret="1" tert="1760421312965" comanda="" tipdoc="AC" numarDoc="1" pentruValidare="1" ora="1102" totaldocument="4378.94" totalincasari="4378.94" descarcarePrioritara="0">
    <pozitii>
      <row contract="" cod="KIT5500C" denumire="UNI-Kit cos de fum coaxial orizontal" cantitate="1" um="BUC" pretcatalog="93.93" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="93.93" valoare="93.93" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="93.93" tip="21" observatii="1 BUC x 93.93" valoarefaradiscount="93.93" tva="18.18" pretftva="75.75" valftva="75.75" nrlinie="1" />
      <row contract="" cod="11010384RO" denumire="UNI-Cazan mural EVE 05 CTFS 24 F" cantitate="1" um="BUC" pretcatalog="2001.36" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="2001.36" valoare="2001.36" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="2001.36" tip="21" observatii="1 BUC x 2001.36" valoarefaradiscount="2001.36" tva="387.36" pretftva="1614.00" valftva="1614.00" nrlinie="2" />
      <row contract="" cod="0232120" denumire="TRUST-Vana de descarcare termica STS20" cantitate="1" um="BUC" pretcatalog="254.7" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="254.7" valoare="254.7" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="254.70" tip="21" observatii="1 BUC x 254.7" valoarefaradiscount="254.7" tva="49.30" pretftva="205.40" valftva="205.40" nrlinie="3" />
      <row contract="" cod="311530" denumire="ROU-Supapa de siguranta standard, M-M, 3/4x3/4&quot;&quot;, 3bari" cantitate="1" um="BUC" pretcatalog="58.84" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="58.84" valoare="58.84" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="58.84" tip="21" observatii="1 BUC x 58.84" valoarefaradiscount="58.84" tva="11.39" pretftva="47.45" valftva="47.45" nrlinie="4" />
      <row contract="" cod="702000026" denumire="MM-Vana cu 3 cai, rotativa, cu filet interior, 1&quot;&quot;1/4, V3000 VDM3" cantitate="1" um="BUC" pretcatalog="243.41" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="243.41" valoare="243.41" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="243.41" tip="21" observatii="1 BUC x 243.41" valoarefaradiscount="243.41" tva="47.11" pretftva="196.30" valftva="196.30" nrlinie="5" />
      <row contract="" cod="96635045" denumire="GRU-Pompa de circulatie cu doua trepte de turatie UP BASIC 32-60" cantitate="1" um="BUC" pretcatalog="473.12" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="473.12" valoare="473.12" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="473.12" tip="21" observatii="1 BUC x 473.12" valoarefaradiscount="473.12" tva="91.57" pretftva="381.55" valftva="381.55" nrlinie="6" />
      <row contract="" cod="96635040" denumire="GRU-Pompa de circulatie cu doua trepte de turatie UP BASIC 25-40" cantitate="2" um="BUC" pretcatalog="344.16" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="344.16" valoare="688.32" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="344.16" tip="21" observatii="2 BUC x 344.16" valoarefaradiscount="688.32" tva="133.22" pretftva="277.55" valftva="555.10" nrlinie="7" />
      <row contract="" cod="08029114" denumire="FIV-Filtru Y 1&quot;&quot;1/4" cantitate="1" um="BUC" pretcatalog="74.8" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="74.8" valoare="74.8" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="74.80" tip="21" observatii="1 BUC x 74.8" valoarefaradiscount="74.8" tva="14.48" pretftva="60.32" valftva="60.32" nrlinie="8" />
      <row contract="" cod="00400660" denumire="EM-Purjor 1/2&quot;&quot;" cantitate="2" um="BUC" pretcatalog="17.17" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="17.17" valoare="34.34" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="17.17" tip="21" observatii="2 BUC x 17.17" valoarefaradiscount="34.34" tva="6.65" pretftva="13.85" valftva="27.69" nrlinie="9" />
      <row contract="" cod="08028100" denumire="FIV-Clapet 1&quot;&quot;" cantitate="2" um="BUC" pretcatalog="44.65" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="44.65" valoare="89.3" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="44.65" tip="21" observatii="2 BUC x 44.65" valoarefaradiscount="89.3" tva="17.28" pretftva="36.01" valftva="72.02" nrlinie="10" />
      <row contract="" cod="00402100" denumire="EM-Valva 1/2&quot;&quot;T  x 1/2&quot;&quot;M" cantitate="2" um="BUC" pretcatalog="7.58" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="7.58" valoare="15.16" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="7.58" tip="21" observatii="2 BUC x 7.58" valoarefaradiscount="15.16" tva="2.93" pretftva="6.11" valftva="12.23" nrlinie="11" />
      <row contract="" cod="02016014" denumire="EM-Termostat reglare cu capilar L1000mm" cantitate="1" um="BUC" pretcatalog="38.85" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="38.85" valoare="38.85" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="38.85" tip="21" observatii="1 BUC x 38.85" valoarefaradiscount="38.85" tva="7.52" pretftva="31.33" valftva="31.33" nrlinie="12" />
      <row contract="" cod="02012050" denumire="EM-Termostat de imersie" cantitate="1" um="BUC" pretcatalog="66.33" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="66.33" valoare="66.33" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="66.33" tip="21" observatii="1 BUC x 66.33" valoarefaradiscount="66.33" tva="12.84" pretftva="53.49" valftva="53.49" nrlinie="13" />
      <row contract="" cod="02012040" denumire="EM-Termostat cu contact" cantitate="1" um="BUC" pretcatalog="52.39" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="52.39" valoare="52.39" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="52.39" tip="21" observatii="1 BUC x 52.39" valoarefaradiscount="52.39" tva="10.14" pretftva="42.25" valftva="42.25" nrlinie="14" />
      <row contract="" cod="00610612" denumire="EM-Termometru de imersie, 50mm, 1/2&quot;&quot;" cantitate="2" um="BUC" pretcatalog="22.73" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="22.73" valoare="45.46" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="22.73" tip="21" observatii="2 BUC x 22.73" valoarefaradiscount="45.46" tva="8.80" pretftva="18.33" valftva="36.66" nrlinie="15" />
      <row contract="" cod="00600012" denumire="EM-Termomanometru cu conectare posterioara, 80mm" cantitate="1" um="BUC" pretcatalog="55.94" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="55.94" valoare="55.94" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="55.94" tip="21" observatii="1 BUC x 55.94" valoarefaradiscount="55.94" tva="10.83" pretftva="45.11" valftva="45.11" nrlinie="16" />
      <row contract="" cod="00510686" denumire="EM-Teaca ptr sonde, 10/100 mm" cantitate="1" um="BUC" pretcatalog="25.79" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="25.79" valoare="25.79" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="25.79" tip="21" observatii="1 BUC x 25.79" valoarefaradiscount="25.79" tva="4.99" pretftva="20.80" valftva="20.80" nrlinie="17" />
      <row contract="" cod="08028114" denumire="FIV-Clapet 1&quot;&quot; 1/4" cantitate="1" um="BUC" pretcatalog="66.9" cotatva="24" discount="0" yso_stocinstalatori="1" yso_gestpredte="700" explicatii="MARIUS BARBUR" comanda_asis="1760421312965" pret="66.9" valoare="66.9" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="66.90" tip="21" observatii="1 BUC x 66.9" valoarefaradiscount="66.9" tva="12.95" pretftva="53.95" valftva="53.95" nrlinie="18" />
      <row denumire="Numerar" tipLinie="Incasare" tip="31" pret="4378.94" cantitate="1" valoare="4378.94" nrlinie="19" />
    </pozitii>
  </document>
</date>')
exec wScriuDatePV @sesiune='',@parXML=@p2
--select @p2
GO

--aici am apelat descarcarea efectiva a bonului dupa identificatorul unic trimis in apelul scriudatepv de mai sus
declare @p xml='<row UID="96DC6297-3DFB-EA11-13FC-2FF06BBF41FF" />'
exec wDescarcBon '',@p
go

--aici am cautat sa vad de ce el incearca sa faca descarcarea din gestiunea 211 desi bonul a fost facut din comanda de pe gest 700
--am gasit ca scriudatepv a pus in gestiunea fiecarei pozitii alta gestiune decat cea primita in parametrul xml la apelul de mai sus
select a.Bon
	,b.Loc_de_munca,b.*
from bt b inner join antetBonuri a on a.IdAntetBon=b.idAntetBon
where a.UID='96DC6297-3DFB-EA11-13FC-2FF06BBF41FF' 
go

--aici am cautat sa vad de cand a inceput acest lucru sa se intample si cred ca din data de 01.10.2012 cand am pus noile ob ria (deci si pvria)
--am observat ca pt bonul idAntetBon=1348 descarcarea a reusit (desi gest pozitiei 211.1 difera de gestpozbonxml 211) fiindca, intamplator
--, gest de pe com livr (211) era chiar cea asociata GESTPV (211)
select ab.gestiune as gestpozbonxml,b.Loc_de_munca,ab.comanda_asis comanda_asis_xml,b.Comanda_asis,ab.[contract] as contract_xml,b.[Contract],* 
from bonuri b inner join 
	(select
			a.Casa_de_marcat, a.Chitanta,a.Numar_bon,a.Data_bon data,a.Vinzator,a.Tert,a.Gestiune gestantet,'' as ora,
			isnull(xA.row.value('../@tipdoc', 'varchar(20)'),'') as tipdoc,
			xA.row.value('@nrlinie', 'int') as nrlinie,
			xA.row.value('@tip', 'varchar(2)') as tip,
			xA.row.value('@cod', 'varchar(20)') as cod,
			xA.row.value('@barcode', 'varchar(50)') as barcode,
			xA.row.value('@codUM', 'varchar(50)') as um,
			xA.row.value('@cantitate', 'decimal(10,3)') as cantitate,
			xA.row.value('@pret','decimal(10,3)') as pret,
			xA.row.value('@pretcatalog','decimal(10,3)') as pretcatalog,
			xA.row.value('@cotatva', 'decimal(5,2)') as cotatva,
			xA.row.value('@valoare',' decimal(10,2)') as valoare,
			xA.row.value('@tva',' decimal(10,2)') as tva,
			xA.row.value('@discount',' decimal(10,2)') as discount,
			xA.row.value('@denumire',' varchar(120)') as denumire,
			xA.row.value('@iddocumentincasare',' varchar(20)') as iddocumentincasare,
			xA.row.value('@gestiune',' varchar(20)') as gestiune, -- se trimite pentru comenzi/devize
			xA.row.value('@lm',' varchar(20)') as lm,
			xA.row.value('@comanda_asis',' varchar(20)') as comanda_asis,
			xA.row.value('@contract',' varchar(20)') as [contract]
			from antetbonuri a
			cross apply	bon.nodes('date/document/pozitii/row') as xA(row)
			where bon is not null --and a.UID='96DC6297-3DFB-EA11-13FC-2FF06BBF41FF'
			) as ab 
	on ab.Data=b.Data and ab.Casa_de_marcat=b.Casa_de_marcat and ab.Vinzator=b.Vinzator and ab.Numar_bon=b.Numar_bon 
		and ab.nrlinie=b.Numar_linie
where ab.gestiune<>b.Loc_de_munca and isnull(ab.Comanda_asis,'')=isnull(b.Comanda_asis,'') 
		and ISNULL(ab.[Contract],'')=ISNULL(b.[Contract],'')	
