--***
create procedure wIaComenzi @sesiune varchar(50), @parXML xml
as
declare @subunitate varchar(9), @GenComPBK int, @fltComanda varchar(20), @fltTipComanda varchar(1), @fltDescriere varchar(80),
	@fltPerioadaJos datetime, @fltPerioadaSus datetime, @fltGrupa varchar(20), @fltDenGrupa varchar(30),
	@fltLM varchar(9), @fltDenLM varchar(30), @fltBeneficiar varchar(13), @fltDenBeneficiar varchar(80),
	@fltTehnologie varchar(20), @fltDenTehnologie varchar(80), @utilizator varchar(200), @areDetalii bit

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null 
	return -1


select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'
select @GenComPBK=val_logica from par where tip_parametru='UC' and parametru='GENCOMPBK'

select @fltComanda=isnull(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''),
	@fltTipComanda=isnull(@parXML.value('(/row/@tipcomanda)[1]', 'varchar(1)'), ''),
	@fltDescriere=isnull(@parXML.value('(/row/@dencomanda)[1]', 'varchar(80)'), ''),
	@fltPerioadaJos=isnull(@parXML.value('(/row/@perioadajos)[1]', 'datetime'), '01/01/1901'),
	@fltPerioadaSus=isnull(@parXML.value('(/row/@perioadasus)[1]', 'datetime'), '12/31/2999'),
	@fltGrupa=isnull(@parXML.value('(/row/@grupa)[1]', 'varchar(20)'), ''),
	@fltDenGrupa=isnull(@parXML.value('(/row/@dengrupa)[1]', 'varchar(30)'), ''),
	@fltLM=isnull(@parXML.value('(/row/@lm)[1]', 'varchar(9)'), ''),
	@fltDenLM=isnull(@parXML.value('(/row/@denlm)[1]', 'varchar(30)'), ''),
	@fltBeneficiar=isnull(@parXML.value('(/row/@beneficiar)[1]', 'varchar(13)'), ''),
	@fltDenBeneficiar=isnull(@parXML.value('(/row/@denbeneficiar)[1]', 'varchar(80)'), ''),
	@fltTehnologie=isnull(@parXML.value('(/row/@tehnologie)[1]', 'varchar(20)'), ''),
	@fltDenTehnologie=isnull(@parXML.value('(/row/@dentehnologie)[1]', 'varchar(80)'), '')

select @fltDescriere=replace(@fltDescriere,' ','%'),
	@fltDenGrupa=replace(@fltDenGrupa,' ','%'),
	@fltDenLM=replace(@fltDenLM,' ','%'),
	@fltDenBeneficiar=replace(@fltDenBeneficiar,' ','%')
	
	if OBJECT_ID('tempdb..#wCom') is not null
		drop table #wCom
	
	
select top 100 rtrim(c.Comanda) as comanda, rtrim(c.tip_comanda) as tipcomanda, rtrim(dbo.denTipComanda(c.tip_comanda)) as dentipcomanda, 
rtrim(c.descriere) as dencomanda, 
convert(char(10), c.data_lansarii, 101) as datalansarii, convert(char(10), c.data_inchiderii, 101) as datainchiderii,
rtrim(c.starea_comenzii) as stareacomenzii, rtrim(dbo.denStareComanda(c.starea_comenzii)) as denstareacomenzii, 
rtrim(c.loc_de_munca) as lm, rtrim(isnull(lm.denumire, '')) as denlm, 
rtrim(case when c.tip_comanda='T' then c.numar_de_inventar else '' end) as numardeinventar, 
--aici ar trebuie sa verifice comisaru ce se intampla
--convert(char(10),convert(datetime, (case when c.tip_comanda<>'T' then c.numar_de_inventar else '1901/01/01' end), 111), 101) as termen, 
rtrim(c.beneficiar) as beneficiar, rtrim(isnull(t.denumire, '')) as denbeneficiar,
rtrim(case when c.tip_comanda in ('X', 'T') then c.loc_de_munca_beneficiar else '' end) as lmbenef, rtrim(isnull(lmb.denumire, '')) as denlmbenef, 
rtrim(case when c.tip_comanda not in ('P', 'R') then c.comanda_beneficiar else '' end) as comandabenef, rtrim(isnull(cb.descriere, '')) as dencomandabenef,
rtrim(case when c.tip_comanda in ('P', 'R') then c.comanda_beneficiar else '' end) as contract, rtrim(isnull(conb.explicatii, '')) as dencontract,
rtrim(case when c.tip_comanda in ('P', 'R', 'A') then c.art_calc_benef else '' end) as observatii, 
rtrim(case when c.tip_comanda not in ('P', 'R', 'A') then c.art_calc_benef else '' end) as artcalcbenef, rtrim(isnull(artcalc.denumire, '')) as denartcalcbenef, 
rtrim(isnull(gr.cod_produs, '')) as grupa, rtrim(isnull(grcom.denumire_grupa, '')) as dengrupa, 
rtrim(isnull(p.cod_produs, '')) as tehnologie, 
(CASE c.starea_comenzii  when  'I' THEN '#808080' when 'L' then '#FF0000' else '#000000' END) AS culoare,
--rtrim(isnull(tehn.denumire, '')) as dentehnologie, 
convert(decimal(12, 3), isnull(p.cantitate, 0)) as cantitate, rtrim(isnull(p.UM, '')) as um, rtrim(isnull(um.denumire, '')) as denum
into #wCom
from Comenzi c
left join pozcom gr on gr.Subunitate='GR' and gr.Comanda=c.Comanda
left join lm on lm.cod=c.loc_de_munca
left join terti t on t.subunitate=c.subunitate and t.tert=c.beneficiar
left join lm lmb on c.tip_comanda in ('X', 'T') and lmb.cod=c.loc_de_munca_beneficiar
left join comenzi cb on c.tip_comanda not in ('P', 'R') and cb.subunitate=c.subunitate and cb.comanda=c.comanda_beneficiar
left join con conb on c.tip_comanda in ('P', 'R') and conb.subunitate=c.subunitate and conb.tip=(case when @GenComPBK=1 then 'BK' else 'BF' end) and conb.contract=c.comanda_beneficiar
left join artcalc on c.tip_comanda not in ('P', 'R', 'A') and artcalc.articol_de_calculatie=c.art_calc_benef
left join grcom on gr.cod_produs is not null and grcom.tip_comanda=c.tip_comanda and grcom.grupa=gr.cod_produs
left join 
(
	select comanda, cod_produs, cantitate, UM, 
		row_number() OVER (partition by comanda order by cod_produs) as ordine
	from pozcom
	where subunitate=@subunitate and cod_produs<>''
) p on p.comanda=c.comanda and p.ordine=1
--left join tehn on tehn.cod_tehn=p.cod_produs
left join um on um.UM=p.UM
where c.subunitate=@subunitate
and c.comanda like '%'+@fltComanda+'%'
and c.descriere like '%'+@fltDescriere+'%'
and (@fltTipComanda='' or c.tip_comanda=@fltTipComanda)
and c.data_lansarii between @fltPerioadaJos and @fltPerioadaSus
and isnull(gr.cod_produs, '') like @fltGrupa + '%'
and isnull(grcom.denumire_grupa, '') like '%' + @fltDenGrupa + '%'
and c.loc_de_munca like @fltLM + '%'
and isnull(lm.denumire, '') like '%' + @fltDenLM + '%'
and c.beneficiar like @fltBeneficiar + '%'
and isnull(t.denumire, '') like '%' + @fltDenBeneficiar + '%'
and isnull(p.cod_produs, '') like @fltTehnologie + '%'
--and isnull(tehn.denumire, '') like '%' + @fltDenTehnologie + '%'
order by c.Comanda


IF EXISTS (
		SELECT 1
		FROM syscolumns sc, sysobjects so
		WHERE so.id = sc.id
			AND so.NAME = 'comenzi'
			AND sc.NAME = 'detalii'
		)
BEGIN
	SET @areDetalii = 1

	ALTER TABLE #wCom ADD detalii XML
	
	update #wCom  set detalii= c.detalii
	from comenzi c
	where c.Comanda=#wCom.comanda
END
ELSE
	SET @areDetalii = 0

select * from #wCom
for xml raw,root('Date')

select @areDetalii as areDetaliiXml
for xml raw,root('Mesaje')
