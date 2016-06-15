--***
create procedure [dbo].[wIaMPdoc] @sesiune varchar(50), @parXML xml as  
  
declare @subunitate varchar(20), @userASiS varchar(20), @iDoc int, @lista_gestiuni bit, @lista_lm bit
select @userASiS=id from utilizatori where observatii=SUSER_NAME()

select @lista_gestiuni=0, @lista_lm=0
select @lista_gestiuni=(case when cod_proprietate='GESTIUNE' then 1 else @lista_gestiuni end), 
	@lista_lm=(case when cod_proprietate='LOCMUNCA' then 1 else @lista_lm end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'LOCMUNCA') and valoare<>''

select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'

exec sp_xml_preparedocument @iDoc output, @parXML

select top 100 
rtrim(d.subunitate) as subunitate, rtrim(d.tip) as tip, rtrim(d.numar) as numar, convert(varchar(10),d.data,101) as data, 
convert (int, d.schimb) as schimb, convert (int, d.sarja) as sarja, rtrim(d.gest_prod) as gestprod, isnull(rtrim(left( gp.denumire_gestiune,30)),'') as dengp, rtrim(d.gest_mat) as gestmat, isnull(rtrim(left( gm.denumire_gestiune,30)),'') as dengm, rtrim(d.loc_munca) as lm, isnull(rtrim( lm.denumire),'') as denlm, rtrim(d.comanda) as com, isnull(rtrim( c.descriere),'') as dencom, rtrim(d.sef_schimb) as sef, isnull(rtrim( ps.nume),'') as numes, rtrim(d.mecanic_schimb) as mecanic, isnull(rtrim( pm.nume),'') as numem, convert (int, d.nr_pers_schimb) as nrpers

FROM mpdoc d 
cross join OPENXML(@iDoc, '/row')
	WITH
	(
		tip varchar(2) '@tip',
		numar varchar(8) '@numar',
		datajos datetime '@datajos',
		datasus datetime '@datasus',
		gestprod varchar(9) '@gestprod',
		dengp varchar(30) '@dengp',
		gestmat varchar(9) '@gestmat',
		dengm varchar(30) '@dengm',
		lm varchar(9) '@lm',
		denlm varchar(30) '@denlm'
	) as fx
left outer join gestiuni gp on gp.subunitate = d.subunitate and gp.cod_gestiune = d.gest_prod 
left outer join gestiuni gm on gm.subunitate = d.subunitate and gm.cod_gestiune = d.gest_mat
left outer join lm on lm.cod = d.loc_munca 
left outer join comenzi c on c.subunitate = d.subunitate and c.comanda = d.comanda
left outer join personal ps on ps.marca = d.sef_schimb
left outer join personal pm on pm.marca = d.mecanic_schimb
/*left outer join proprietati gu on gu.valoare=d.gest_prod and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'
left outer join proprietati gpu on gpu.valoare=d.gest_mat and gpu.tip='UTILIZATOR' and gpu.cod=@userASiS and gpu.cod_proprietate='GESTIUNE'*/
WHERE d.subunitate=@subunitate and d.tip = fx.tip and d.numar like isnull(fx.numar, '%') 
and d.data between isnull(fx.datajos, '01/01/1901') and (case when isnull(fx.datasus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.datasus end)
and d.gest_prod like isnull(fx.gestprod, '') + '%' 
 and left(isnull( gp.denumire_gestiune, ''), 30) like '%' + isnull(fx.dengp, '') + '%'
and d.gest_mat like isnull(fx.gestmat, '') + '%' 
 and left(isnull( gm.denumire_gestiune, ''), 30) like '%' + isnull(fx.dengm, '') + '%'
and d.loc_munca like isnull(fx.lm, '') + '%'
and isnull(lm.denumire, '') like '%' + isnull(fx.denlm, '') + '%'
/*and (@lista_gestiuni=0 or gu.valoare is not null or gpu.Valoare is not null)
and (@lista_lm=0 or exists (select 1 from proprietati lu where RTrim(d.loc_munca) like RTrim(lu.valoare)+'%' and lu.tip='UTILIZATOR' and lu.cod=@userASiS and lu.cod_proprietate='LOCMUNCA'))*/
order by data desc
for xml raw

exec sp_xml_removedocument @iDoc
