--***
Create procedure wIaPozSalarii @sesiune varchar(50), @parXML xml
as  
declare @userASiS varchar(10), @iDoc int, @tip varchar(20), @subtip varchar(20), @lmantet varchar(9), @tipcor varchar(2), @codbenef varchar(13), 
@data datetime, @dataj datetime, @datas datetime, @lPremiu_la_avans int, @CorectiiNete int, @cautare varchar(500)

set @lPremiu_la_avans=dbo.iauParL('PS','PREMAVANS')
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(20)'), @subtip=xA.row.value('@subtip', 'varchar(20)'), 
@lmantet=xA.row.value('@lmantet', 'varchar(9)'), @tipcor=xA.row.value('@tipcor', 'varchar(2)'), @codbenef=xA.row.value('@codbenef', 'varchar(13)')
from @parXML.nodes('row') as xA(row) 

select @cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), '')
set @dataj=dbo.bom(@data)
set @datas=dbo.eom(@data)
set @CorectiiNete=isnull((select count(1) from webConfigTipuri where meniu='SL' and tip='CN' and ISNULL(subtip,'')='' and vizibil=1),0)

select 
convert(char(10),a.data,101) as data, rtrim(a.marca) as marca, rtrim(p.nume) as densalariat, 
1 as numarpozitie, @tip as tip, (case when @tip='SL' then 'A1' else 'A2' end) as subtip, 
'Avans'+space(25) as denumire, '' as nrdoc, rtrim(p.Loc_de_munca) as codac, 'Avans' as explicatii,
convert(decimal(12,2),a.Ore_lucrate_la_avans) as cantitate, convert(decimal(12,2),a.Suma_avans) as valoare, 
convert(decimal(12,2),a.Ore_lucrate_la_avans) as oreavans, convert(decimal(12,2),a.Suma_avans) as sumaavans, 
convert(decimal(12,2),a.Premiu_la_avans) as premiuavans, 
Null as sumaneta, Null as sumacorectie, Null as procentcorectie, Null as tipachitare, Null as dentipachitare, Null as sumaachitata, 
Null as procent, Null as progrlich, Null as retinutlich, Null as valtotala, Null as valretinuta, 
Null as datainceput, Null as orainceput, Null as datasfarsit, Null as orasfarsit, Null as tipconcediu, Null as denconcediu, 
Null as zileunitate, Null as zilecas, Null as indunitate, Null as indcas, 
Null as seriecm, Null as numarcm, Null as cminitial, Null as dencminitial, Null as coddiagnostic, Null as codurgenta, Null as codgrupaa, 
Null as dataacordarii, Null as cnpcopil, Null as locprescriere, Null as medicprescriptor, Null as unitatesanitara, 
Null as nravizme, Null as mediazilnica, Null as bazastagiu, Null as zilestagiu, Null as calculmanual, 
Null as zileco, Null as indemnizatieco, Null as indnetaco, Null as dataop, Null as zileca, Null as oreca, 
Null as nrcrt, Null as lm, Null as denlm, Null as comanda, Null as dencomanda, 
Null as tipsal, Null as oreregie, Null as oreacord, Null as oresupl1, Null as oresupl2, Null as oresupl3, Null as oresupl4, Null as orespor100, 
Null as orenoapte,  Null as orerealizate, Null as realizat, Null as coefacord, Null as salcatl, Null as oredetasare, Null as oredelegatii, Null as orelucrate, 
Null as oreco, Null as orecm, Null as oreintr1, Null as oreintr2, Null as oreobligatii, Null as oreinvoiri, Null as orenemotivate, Null as orecfs, Null as orenelucrate, 
Null as sporspecific, Null as orepesteprogr, Null as sppesteprogr, Null as ore1, Null as sp1, Null as ore2, Null as sp2, 
Null as ore3, Null as sp3, Null as ore4, Null as sp4, Null as ore5, Null as sp5, Null as ore6, Null as sp6, Null as sp7, Null as sp8, 
Null as tipcor, Null as dentipcor, Null as codbenef, Null as denbenef, 
Null as tiptichet, Null as serieinceput, Null as seriesfarsit, Null as nrtichete, Null as valtichet, Null as valtichete, 
rtrim((case when 1=0 then a.marca else p.nume end)) as Ordonare, 
'#000000' as culoare 
from avexcep a 
	left outer join personal p on p.marca=a.marca, @parXML.nodes('row') as xA(row)
where (@tip='SL' and a.marca=xA.row.value('@marca','varchar(6)') or @tip='AV' and p.loc_de_munca=@lmantet 
	and (a.Marca like @cautare+'%' or p.Nume like '%'+@cautare+'%')) and a.data between @dataj and @datas
union all
select a.data, rtrim(a.marca) as marca, rtrim(a.nume) as densalariat, a.numar_pozitie, a.tip, a.subtip, rtrim(a.denumire) as denumire, rtrim(a.nrdoc) as nrdoc, 
rtrim(a.codac) as codac, rtrim(a.explicatii) as explicatii, a.cantitate, a.valoare,
Null as oreavans, Null as sumaavans, Null as premiuavans, 
Null as sumaneta, Null as sumacorectie, Null as procentcorectie, Null as tipachitare, Null as dentipachitare, Null as sumaachitata, 
Null as procent, Null as progrlich, Null as retinutlich, Null as valtotala, Null as valretinuta, 
Null as datainceput, Null as orainceput, Null as datasfarsit, Null as orasfarsit, Null as tipconcediu, Null as denconcediu, 
Null as zileunitate, Null as zilecas, Null as indunitate, Null as indcas, 
Null as seriecm, Null as numarcm, Null as cminitial, Null as dencminitial, Null as coddiagnostic, Null as codurgenta, Null as codgrupaa, 
Null as dataacordarii, Null as cnpcopil, Null as locprescriere, Null as medicprescriptor, Null as unitatesanitara, 
Null as nravizme, Null as mediazilnica, Null as bazastagiu, Null as zilestagiu, Null as calculmanual, 
Null as zileco, Null as indemnizatieco, Null as indnetaco, Null as dataop, Null as zileca, Null as oreca, 
a.numar_curent as nrcrt, rtrim(a.lm) as lm, rtrim(a.denlm) as denlm, rtrim(a.comanda) as comanda, rtrim(a.dencomanda) as dencomanda, 
a.tipsal, a.oreregie, a.oreacord, a.oresupl1, a.oresupl2, a.oresupl3, a.oresupl4, a.orespor100, a.orenoapte,  a.orerealizate, a.realizat, a.coefacord, 
a.salcatl as salcatl, a.oredetasare, a.oredelegatii, a.orelucrate,
a.oreco, a.orecm, a.oreintr1, a.oreintr2, a.oreobligatii, a.oreinvoiri, a.orenemotivate, a.orecfs, a.orenelucrate, 
a.sporspecific, a.orepesteprogr, a.sppesteprogr, a.ore1, a.sp1, a.ore2, a.sp2, a.ore3, a.sp3, a.ore4, a.sp4, a.ore5, a.sp5, a.ore6, a.sp6, a.sp7, a.sp8, 
Null as tipcor, Null as dentipcor, Null as codbenef, Null as denbenef, 
Null as tiptichet, Null as serieinceput, Null as seriesfarsit, nrtichete as nrtichete, Null as valtichet, Null as valtichete, 
rtrim((case when 1=0 then a.marca else a.nume end)) as Ordonare, 
(case when exists (select c.Marca from conmed c where c.data=dbo.EOM(a.data) and c.Marca=a.Marca and c.Tip_diagnostic='0-') then '#CC0033' else '#0000FF' end) as culoare
from dbo.wfIaDLPontaj (@parXML) a
where (@tip='SL' or @tip='PO' and  (a.Marca like @cautare+'%' or a.Nume like '%'+@cautare+'%'))
union all
select data, rtrim(marca) as marca, rtrim(nume) as densalariat, numar_pozitie, tip, subtip, 
rtrim(denumire)+' '+rtrim(denconcediu) as denumire, rtrim(nrdoc) as nrdoc, 
rtrim(tipconcediu) as codac, rtrim(denconcediu) as explicatii, cantitate, valoare,
Null as oreavans, Null as sumaavans, Null as premiuavans, Null as sumaneta, 
Null as sumacorectie, Null as procentcorectie, Null as tipachitare, Null as dentipachitare, Null as sumaachitata, 
procent as procent, Null as progrlich, Null as retinutlich, Null as valtotala, Null as valretinuta, datainceput, orainceput, datasfarsit, orasfarsit,
rtrim(tipconcediu) as tipconcediu, rtrim(denconcediu) as denconcediu, zileunitate, zilecas, indunitate, indcas, 
rtrim(seriecm), rtrim(numarcm), rtrim(cminitial), rtrim(dencminitial), rtrim(coddiagnostic), rtrim(codurgenta), rtrim(codgrupaa), dataacordarii, rtrim(cnpcopil), locprescriere, 
rtrim(medicprescriptor), rtrim(unitatesanitara), rtrim(nravizme), mediazilnica, bazastagiu as bazastagiu, zilestagiu as zilestagiu, calculmanual as calculmanual, 
zileco as zileco, indemnizatieco as indemnizatieco, indnetaco as indnetaco, convert(char(10),dataoperarii,101) as dataop, zileconalte as zileca, oreconalte as oreca, 
numar_curent as nrcrt, rtrim(lm) as lm, rtrim(denlm) as denlm, rtrim(comanda) as comanda, rtrim(dencomanda) as dencomanda, 
Null as tipsal, Null as oreregie, Null as oreacord, Null as oresupl1, Null as oresupl2, Null as oresupl3, Null as oresupl4, Null as orespor100, 
Null as orenoapte,  Null as orerealizate, Null as realizat, Null as coefacord, Null as salcatl, Null as oredetasare, Null as oredelegatii, Null as orelucrate, 
Null as oreco, Null as orecm, Null as oreintr1, Null as oreintr2, Null as oreobligatii, Null as oreinvoiri, Null as orenemotivate, Null as orecfs,Null as orenelucrate, 
Null as sporspecific, Null as orepesteprogr, Null as sppesteprogr, Null as ore1, Null as sp1,Null as ore2, Null as sp2, Null as ore3, 
Null as sp3, Null as ore4, Null as sp4, Null as ore5, Null as sp5, Null as ore6, Null as sp6, Null as sp7, Null as sp8, 
Null as tipcor, Null as dentipcor, Null as codbenef, Null as denbenef, 
Null as tiptichet, Null as serieinceput, Null as seriesfarsit, Null as nrtichete, Null as valtichet, Null as valtichete, 
rtrim((case when 1=0 then marca else nume end)) as Ordonare, 
(case when tip in ('SL') and subtip like 'M'+'%' then'#FF0000' else '#000000' end) as culoare
from dbo.wfIaDLConcedii (@sesiune, @parXML) 
where (@tip='SL' or tip=@tip  and (Marca like @cautare+'%' or Nume like '%'+@cautare+'%' or lm like @cautare+'%' or denlm like '%'+@cautare+'%' 
	or tipconcediu like @cautare+'%' or denconcediu like '%'+@cautare+'%') 
	or numarcm like '%'+@cautare+'%' or cminitial like '%'+@cautare+'%') 
union all
select 
convert(char(10),c.data,101) as data, rtrim(c.marca) as marca, rtrim(p.nume) as densalariat, 
(case when c.Suma_neta=0 then 11 else 12 end) as numarpozitie, @tip as tip, 
(case when @tip='CL' then 'C5' when c.Suma_neta<>0 and @CorectiiNete<>0 then (case when @tip='SL' then 'C3' else 'C4' end) 
else (case when @tip='SL' then 'C1' else 'C2' end) end) as subtip, 
(case when @tip='CL' then 'Corectii pe locuri de munca' when c.Suma_neta<>0 and @CorectiiNete<>0 then 'Corectii nete ' 
else 'Corectii ' end)+rtrim(tc.Denumire) as denumire, 
'' as nrdoc, rtrim(c.Tip_corectie_venit) as codac, rtrim(tc.Denumire) as denac, 
convert(decimal(12,2),c.Suma_neta) as cantitate, 
convert(decimal(12,2),c.Suma_corectie) as valoare, Null as oreavans, Null as sumaavans, Null as premiuavans, 
convert(decimal(12,2),c.Suma_neta) as sumaneta, convert(decimal(12,2),c.Suma_corectie) as sumacorectie, 
(case when c.Suma_neta<>0 then Null else convert(decimal(12,2),c.Procent_corectie) end) as procentcorectie, 
isnull(convert(int,isnull(ca.Procent_corectie,0)),0) as tipachitare, 
(case when isnull(ca.Procent_corectie,0)=1 then 'Avans' when isnull(ca.Procent_corectie,0)=2 then 'Lichidare' 
when isnull(ca.Procent_corectie,0)=3 then 'Alta data' when isnull(ca.Procent_corectie,0)=4 then 'Casa' else 'Neinregistrat' end) as dentipachitare,
convert(decimal(12,2),isnull(ca.Suma_corectie,0)) as sumaachitata, 
Null as procent, Null as progrlich, Null as retinutlich, Null as valtotala, Null as valretinuta, 
Null as datainceput, Null as orainceput, Null as datasfarsit, Null as orasfarsit, Null as tipconcediu, Null as denconcediu, 
Null as zileunitate, Null as zilecas, Null as indunitate, Null as indcas, 
Null as seriecm, Null as numarcm, Null as cminitial, Null as dencminitial, Null as coddiagnostic, Null as codurgenta, Null as codgrupaa, 
Null as dataacordarii, Null as cnpcopil, Null as locprescriere, Null as medicprescriptor, Null as unitatesanitara, 
Null as nravizme, Null as mediazilnica, Null as bazastagiu, Null as zilestagiu, Null as calculmanual, 
Null as zileco, Null as indemnizatieco, Null as indnetaco, Null as dataop, Null as zileca, Null as oreca, Null as nrcrt, 
rtrim(c.loc_de_munca) as lm, rtrim(lm.denumire) as denlm, Null as comanda, Null as dencomanda, 
Null as tipsal, Null as oreregie, Null as oreacord, Null as oresupl1, Null as oresupl2, Null as oresupl3, Null as oresupl4, Null as orespor100, 
Null as orenoapte, Null as orerealizate, Null as realizat, Null as coefacord, Null as salcatl, Null as oredetasare, Null as oredelegatii, Null as orelucrate, 
Null as oreco, Null as orecm, Null as oreintr1, Null as oreintr2, Null as oreobligatii, Null as oreinvoiri, Null as orenemotivate, Null as orecfs, Null as orenelucrate, 
Null as sporspecific, Null as orepesteprogr, Null as sppesteprogr, Null as ore1, Null as sp1, Null as ore2, Null as sp2, Null as ore3, 
Null as sp3, Null as ore4, Null as sp4, Null as ore5,Null as sp5, Null as ore6, Null as sp6, Null as sp7, Null as sp8, 
rtrim(c.Tip_corectie_venit) as tipcor, rtrim(tc.Denumire) as dentipcor, Null as codbenef, Null as denbenef, 
Null as tiptichet, Null as serieinceput, Null as seriesfarsit, Null as nrtichete, Null as valtichet, Null as valtichete, 
rtrim((case when 1=0 then c.marca else p.nume end)) as Ordonare, 
'#000000' as culoare 
from 
corectii c
	left outer join tipcor tc on c.Tip_corectie_venit=tc.Tip_corectie_venit
	left outer join lm on c.loc_de_munca=lm.cod
	left outer join personal p on p.marca=c.marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and c.Loc_de_munca=lu.cod
--	legatura pentru pozitia cu corectiile achitate +200 ani
	left outer join corectii ca on ca.Data=DATEADD(YEAR,200,c.Data) and ca.Marca=c.Marca and ca.Loc_de_munca=c.Loc_de_munca and ca.Tip_corectie_venit=c.Tip_corectie_venit
	, @parXML.nodes('row') as xA(row)
where c.data between @dataj and @datas --and (@tip='SL' or @data is null or c.Data=@data)
	and ((@tip in ('CN','CT') or @tip='SL' and c.marca=xA.row.value('@marca','varchar(6)')) and c.marca<>'' or @tip='CL' and c.marca='')
	and (@tip='SL' or (@tip='CN' and c.Suma_neta<>0 and @subtip='C4' or @tip='CT' and @subtip='C2' and (c.Suma_neta=0 or @CorectiiNete=0) or @tip='CL' and @subtip='C5') 
	and c.Tip_corectie_venit=@tipcor)
	and (@tip='SL' or @tip='CL' or (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null))
	and (@tip='SL' or (c.Marca like @cautare+'%' or p.Nume like '%'+@cautare+'%' or /*@tip='CL' and*/ lm.Denumire like '%'+@cautare+'%'))
union all
select 
convert(char(10),r.data,101) as data, rtrim(r.marca) as marca, rtrim(p.nume) as densalariat, 
13 as numarpozitie, @tip as tip, (case when @tip='SL' then 'R1' else 'R2' end), 'Retinere '+rtrim(br.Denumire_beneficiar) as denumire, 
rtrim(r.numar_document) as nrdoc, rtrim(r.cod_beneficiar) as codac, rtrim(br.Denumire_beneficiar) as denac, 
convert(decimal(12,2),r.Retinere_progr_la_lichidare) as cantitate, 
convert(decimal(12,2),r.Retinut_la_lichidare) as valoare, Null as oreavans, Null as sumaavans, Null as premiuavans, 
Null as sumaneta, Null as sumacorectie, Null as procentcorectie, Null as tipachitare, Null as dentipachitare, Null as sumaachitata, 
convert(decimal(12,2),r.Procent_progr_la_lichidare) as procent, convert(decimal(12,2),r.Retinere_progr_la_lichidare) as progrlich, 
convert(decimal(12,2),r.Retinut_la_lichidare) as retinutlich, convert(decimal(12,2),r.Valoare_totala_pe_doc) as valtotala, 
convert(decimal(12,2),r.Valoare_retinuta_pe_doc) as valretinuta, 
Null as datainceput, Null as orainceput, Null as datasfarsit, Null as orasfarsit, Null as tipconcediu, Null as denconcediu, 
Null as zileunitate, Null as zilecas, Null as indunitate, Null as indcas, 
Null as seriecm, Null as numarcm, Null as cminitial, Null as dencminitial, Null as coddiagnostic, Null as codurgenta, Null as codgrupaa, 
Null as dataacordarii, Null as cnpcopil, Null as locprescriere, Null as medicprescriptor, Null as unitatesanitara, 
Null as nravizme, Null as mediazilnica, Null as bazastagiu, Null as zilestagiu, Null as calculmanual, 
Null as zileco, Null as indemnizatieco, Null as indnetaco, Null as dataop, Null as zileca, Null as oreca, 
Null as nrcrt, Null as lm, Null as denlm, Null as comanda, Null as dencomanda, 
Null as tipsal, Null as oreregie, Null as oreacord, Null as oresupl1, Null as oresupl2, Null as oresupl3, Null as oresupl4, Null as orespor100, 
Null as orenoapte,  Null as orerealizate, Null as realizat, Null as coefacord, Null as salcatl, Null as oredetasare, Null as oredelegatii, Null as orelucrate, 
Null as oreco, Null as orecm, Null as oreintr1, Null as oreintr2, Null as oreobligatii, Null as oreinvoiri, Null as orenemotivate, Null as orecfs, Null as orenelucrate, 
Null as sporspecific, Null as orepesteprogr, Null as sppesteprogr, Null as ore1, Null as sp1, Null as ore2, Null as sp2, Null as ore3, 
Null as sp3, Null as ore4, Null as sp4, Null as ore5, Null as sp5, Null as ore6, Null as sp6, Null as sp7, Null as sp8, 
Null as tipcor, Null as dentipcor, rtrim(r.cod_beneficiar) as codbenef, rtrim(br.Denumire_beneficiar) as denbenef, 
Null as tiptichet, Null as serieinceput, Null as seriesfarsit, Null as nrtichete, Null as valtichet, Null as valtichete, 
rtrim((case when 1=0 then r.marca else p.nume end)) as Ordonare, 
'#000000' as culoare 
from 
resal r
	left outer join benret br on r.Cod_beneficiar=br.cod_beneficiar
	left outer join personal p on p.marca=r.marca
	left outer join istpers i on i.Data=r.Data and i.Marca=r.Marca 
	left outer join lm on lm.Cod=i.Loc_de_munca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
	, @parXML.nodes('row') as xA(row)
where r.data between @dataj and @datas 
	and (@tip='SL' and r.marca=xA.row.value('@marca','varchar(6)') or @tip='RE' and r.Cod_beneficiar=@codbenef 
	and (r.Marca like @cautare+'%' or p.Nume like '%'+@cautare+'%' or i.Loc_de_munca like @cautare+'%' or lm.Denumire like '%'+@cautare+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)) 
union all
select convert(char(10),t.data_lunii,101) as data, rtrim(t.marca) as marca, rtrim(p.nume) as densalariat, 
13 as numarpozitie, @tip as tip, (case when @tip='SL' then 'T1' else 'T2' end) as subtip, 
'Tichete '+rtrim((case when t.Tip_operatie='S' then 'Suplimentare' when t.Tip_operatie='C' then 'Cuvenite' 
when t.Tip_operatie='P' then 'Primite' when t.Tip_operatie='R' then 'Retinute' end)) as denumire, 
'' as nrdoc, rtrim(p.Loc_de_munca) as codac, 'Tichete' as explicatii,
convert(decimal(12,2),t.Nr_tichete) as cantitate, convert(decimal(12,2),t.Nr_tichete*t.Valoare_tichet) as valoare, 
Null as oreavans, Null as sumaavans, Null as premiuavans, 
Null as sumaneta, Null as sumacorectie, Null as procentcorectie, Null as tipachitare, Null as dentipachitare, Null as sumaachitata, 
Null as procent, Null as progrlich, Null as retinutlich, Null as valtotala, Null as valretinuta, 
Null as datainceput, Null as orainceput, Null as datasfarsit, Null as orasfarsit, Null as tipconcediu, Null as denconcediu, 
Null as zileunitate, Null as zilecas, Null as indunitate, Null as indcas, 
Null as seriecm, Null as numarcm, Null as cminitial, Null as dencminitial, Null as coddiagnostic, Null as codurgenta, Null as codgrupaa, 
Null as dataacordarii, Null as cnpcopil, Null as locprescriere, Null as medicprescriptor, Null as unitatesanitara, 
Null as nravizme, Null as mediazilnica, Null as bazastagiu, Null as zilestagiu, Null as calculmanual, 
Null as zileco, Null as indemnizatieco, Null as indnetaco, Null as dataop, Null as zileca, Null as oreca, 
Null as nrcrt, rtrim(p.loc_de_munca) as lm, rtrim(lm.denumire) as denlm, Null as comanda, Null as dencomanda, 
Null as tipsal, Null as oreregie, Null as oreacord, Null as oresupl1, Null as oresupl2, Null as oresupl3, Null as oresupl4, Null as orespor100, 
Null as orenoapte,  Null as orerealizate, Null as realizat, Null as coefacord, Null as salcatl, Null as oredetasare, Null as oredelegatii, Null as orelucrate, 
Null as oreco, Null as orecm, Null as oreintr1, Null as oreintr2, Null as oreobligatii, Null as oreinvoiri, Null as orenemotivate, Null as orecfs, Null as orenelucrate, 
Null as sporspecific, Null as orepesteprogr, Null as sppesteprogr, Null as ore1, Null as sp1, Null as ore2, Null as sp2, 
Null as ore3, Null as sp3, Null as ore4, Null as sp4, Null as ore5, Null as sp5, Null as ore6, Null as sp6, Null as sp7, Null as sp8, 
Null as tipcor, Null as dentipcor, Null as codbenef, Null as denbenef, 
rtrim(t.Tip_operatie) as tiptichet, rtrim(Serie_inceput) as serieinceput, rtrim(Serie_sfarsit) as seriesfarsit, 
convert(decimal(12,2),t.Nr_tichete) as nrtichete, convert(decimal(12,2),t.Valoare_tichet) as valtichet, 
convert(decimal(12,2),t.Nr_tichete*t.Valoare_tichet) as valtichete, 
rtrim((case when 1=0 then t.marca else p.nume end)) as Ordonare, 
'#000000' as culoare 
from tichete t 
	left outer join personal p on p.marca=t.marca
	left outer join lm lm on lm.cod=p.Loc_de_munca
	, @parXML.nodes('row') as xA(row)
where (@tip='SL' and t.marca=xA.row.value('@marca','varchar(6)') or @tip='TM' and p.loc_de_munca=@lmantet and (t.Marca like @cautare+'%' or p.Nume like '%'+@cautare+'%')) 
	and t.data_lunii between @dataj and @datas
order by data, Ordonare, numarpozitie, datainceput
for xml raw
