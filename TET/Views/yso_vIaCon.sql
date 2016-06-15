create view yso_vIaCon as
select top 100 
	rtrim(d.subunitate) as subunitate, rtrim(d.tip) as tip
	,CASE d.Tip WHEN 'BF' THEN 'Contract beneficiar' WHEN 'BK' THEN 'Comanda livrare' 
			WHEN 'FA' THEN 'Contract furnizor' WHEN 'FC' THEN 'Comanda aprovizionare' ELSE '' END AS dentip
	,rtrim(d.Contract) as numar, convert(varchar(10),d.data,101) as data, 
	rtrim(d.Explicatii) as explicatii, convert(varchar(10),d.termen,101) as termen, 
	isnull(rtrim(left(gPred.denumire_gestiune,30)),'') as dengestiune, rtrim(d.gestiune) as gestiune,  
	rtrim(isnull(t.denumire,'')) as dentert, rtrim(d.factura) as factura, 
	rtrim(d.Tert) as tert, rtrim(contract_coresp) as contractcor, rtrim(d.Punct_livrare) as punctlivrare,rtrim(inft.Descriere) as denpunctlivrare, 
	isnull(rtrim(lm.denumire),'') as denlm, rtrim(d.loc_de_munca) as lm,
	isnull(rtrim(left(gPrim.denumire_gestiune,30)),'') as dengestprim, rtrim(d.Cod_dobanda) as gestprim, 
	rtrim(d.valuta) as valuta, convert(decimal(13,4),d.curs) as curs, 
	convert(decimal(15,2),d.total_contractat) as valoare,
	convert(decimal(15,2),d.total_tva) as valtva,  
	convert(decimal(15,2),d.total_contractat+d.total_tva) as valtotala, 
	rtrim(isnull(d.Scadenta,'')) as scadenta,
	rtrim(isnull(ext.camp_1,'')) as contclient,
	rtrim(isnull(ext.camp_2,'')) as procpen,
	rtrim(isnull(ext.camp_3,'')) as contr_cadru,
	rtrim(isnull(ext.camp_4,'')) as ext_camp4,
	convert(varchar(10),ext.Camp_5,101) as ext_camp5,
	rtrim(isnull(ext.modificari,'')) as ext_modificari,
	rtrim(isnull(ext.Clauze_speciale,'')) as ext_clauze,
	convert(varchar(10),d.Data_rezilierii,101)as valabilitate,
	convert(int,(select count(1) from pozcon p where p.subunitate=d.subunitate and p.tip=d.tip and p.contract=d.contract and p.data=d.data)) as pozitii, 
	(case when d.tip in ('BF', 'FA') then d.discount else 0 end) as discount, 
	(case when left(d.mod_plata,1)='1' then '1' else '0' end) as comspec,
	--(case	when @period_antet='0' then (case when left(d.mod_plata,1)='1' then '1' else '0' end) 
	--		else (case when d.mod_plata='1' then 'Trimestrial' when d.mod_plata='2' then 'Semestrial'when d.mod_plata='3' then 'Anual' end) 
	--end) as comspec, 
	rtrim(d.stare) as stare, 
	convert(int,d.Dobanda) as categpret,
	isnull(rtrim(cp.Denumire),'')+' ('+LTRIM(str(d.Dobanda))+')' as dencategpret,
	--(case when @areDetalii=1 then '' else null end) as detalii, 
	--( case when @aredetalii='' then  d.detalii else '' end) as detalii,
	d.stare + '-' + (case when isnull(pa.val_alfanumerica, '')<>'' then pa.val_alfanumerica else (case d.Stare when '0' then 'Operat' when '1' then 'Definitiv' when '2' then 'Blocat' when '3' then 'Confirmat' when '4' then 'Expediat' when '5' then 'In vama' when '6' then 'Realizat' when '7' then 'Reziliat' else d.stare end) end) as denstare, 
	RTrim(d.Mod_penalizare) as info1, convert(decimal(15,2),d.Val_reziduala) as info2, d.Sold_initial as info3, d.Procent_penalizare as info4, 
	(case when d.Tip not in ('BF', 'FA') then convert(decimal(15,2),d.discount) else 0 end) as info5, 
	--RTRIM(case when d.Tip not in ('BF', 'FA') then d.Responsabil else '' end) as info6,
	rtrim(isnull(d.responsabil,'')) as info6,
	(case d.Stare when '0' then '#000000' when '1' then '#0000FF' when '4' then '#408080' else '#808080' end) as culoare, 
	(case d.Stare when '0' then 0 else 1 end) as _nemodificabil
from con d 
	left join (select REPLACE(rtrim(Parametru),'STAREBK','') as stare, rtrim(Val_alfanumerica) val_alfanumerica 
					from par where tip_parametru='UC' and parametru like 'STAREBK%') pa on pa.stare=d.stare
	left outer join terti t on t.subunitate = d.subunitate and t.tert = d.tert 
	LEFT join infotert inft on inft.subunitate=t.subunitate and inft.tert=t.tert and d.Punct_livrare=inft.Identificator
	left outer join gestiuni gPred on gPred.subunitate = d.subunitate and gPred.cod_gestiune = d.gestiune 
	left outer join gestiuni gPrim on gPrim.subunitate = d.subunitate and gPrim.cod_gestiune = d.Cod_dobanda 
	left outer join categpret cp on d.Tip='BK' and cp.Categorie = d.Dobanda 
	left outer join lm on lm.cod = d.loc_de_munca 
	left outer join extcon ext on ext.subunitate=d.subunitate and ext.Tip=d.Tip and ext.contract=d.contract and ext.Data=d.Data and ext.tert=d.tert and ext.Numar_pozitie=1
	--left outer join (select valoare from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE') gu on gu.valoare=d.gestiune
	--left outer join (select valoare from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTBK') gpu on d.Tip in ('BF', 'BK', 'BP') and gpu.valoare=d.Cod_dobanda 
	--left outer join proprietati cu on cu.valoare=d.tert and cu.tip='UTILIZATOR' and cu.cod=@userASiS and cu.cod_proprietate='CLIENT'
	--left outer join LMFiltrare lu on lu.utilizator=@userASiS and d.Loc_de_munca=lu.cod
where d.Subunitate='1' --and p.tip='BF'
--order by p.Subunitate, p.Tip, p.Contract, p.Data, p.Tert, p.Cod, p.Numar_pozitie desc
