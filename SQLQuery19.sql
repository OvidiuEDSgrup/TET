/****** Object:  StoredProcedure [dbo].[wIaTerti]    Script Date: 04/26/2012 17:18:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
ALTER procedure [dbo].[wIaTerti] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wIaTertiSP' and type='P')
	exec wIaTertiSP @sesiune, @parXML 
else 
begin
set transaction isolation level READ UNCOMMITTED
Declare @fltTert varchar(13), @fltDenumire varchar(80), @fltCodFiscal varchar(16), 
@fltGrupa varchar(3), @fltDenGrupa varchar(30), @fltJudet varchar(20), @fltDenJudet varchar(30), 
@fltTara varchar(20), @fltDenTara varchar(30), @fltLocalitate varchar(35), @fltDenLocalitate varchar(30), 
@fltTipTert int

select @fltTert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
	@fltDenumire = isnull(@parXML.value('(/row/@dentert)[1]', 'varchar(80)'), ''),
	@fltCodFiscal = isnull(@parXML.value('(/row/@codfiscal)[1]', 'varchar(16)'), ''),
	@fltGrupa = isnull(@parXML.value('(/row/@grupa)[1]', 'varchar(3)'), ''),
	@fltDenGrupa = isnull(@parXML.value('(/row/@dengrupa)[1]', 'varchar(30)'), ''),
	@fltJudet = isnull(@parXML.value('(/row/@judet)[1]', 'varchar(20)'), ''),
	@fltDenJudet = isnull(@parXML.value('(/row/@denjudet)[1]', 'varchar(30)'), ''),
	@fltTara = isnull(@parXML.value('(/row/@tara)[1]', 'varchar(20)'), ''),
	@fltDenTara = isnull(@parXML.value('(/row/@dentara)[1]', 'varchar(30)'), ''),
	@fltLocalitate = isnull(@parXML.value('(/row/@localitate)[1]', 'varchar(35)'), ''),
	@fltDenLocalitate = isnull(@parXML.value('(/row/@denlocalitate)[1]', 'varchar(30)'), ''),
	@fltTipTert = @parXML.value('(/row/@tiptert)[1]', 'int')

declare @subunitate varchar(9), @AdrComp int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
exec luare_date_par 'GE', 'ADRCOMP', @AdrComp output, 0, ''

select @fltDenumire=replace(@fltDenumire, ' ', '%'), 
	@fltDenGrupa=replace(@fltDenGrupa, ' ', '%'), 
	@fltJudet=replace(@fltJudet, ' ', '%'), 
	@fltDenJudet=replace(@fltDenJudet, ' ', '%'), 
	@fltTara=replace(@fltTara, ' ', '%'), 
	@fltDenTara=replace(@fltDenTara, ' ', '%'), 
	@fltLocalitate=replace(@fltLocalitate, ' ', '%'), 
	@fltDenLocalitate=replace(@fltDenLocalitate, ' ', '%')

create table #terti100(tert varchar(13) primary key)

insert #terti100
select top 100 rtrim(t.tert) as tert
from terti t   
left join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
left join judete j on isnull(it.zile_inc, 0)=0 and j.cod_judet=t.judet
left join tari on isnull(it.zile_inc, 0)>0 and tari.cod_tara=t.judet
left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
left join gterti g on t.grupa=g.grupa
where t.subunitate=@subunitate and t.tert like @fltTert+'%' 
and t.denumire like '%'+@fltDenumire+'%'
and t.cod_fiscal like @fltCodFiscal+'%'
and t.grupa like @fltGrupa+'%'
and isnull(g.denumire, '') like '%'+@fltDenGrupa+'%' 
and (case when isnull(it.zile_inc, 0)=0 then t.judet else '' end) like '%'+@fltJudet+'%'
and isnull(j.denumire, t.judet) like '%'+@fltDenJudet+'%'
and (case when isnull(it.zile_inc, 0)>0 then t.judet else '' end) like '%'+@fltTara+'%'
and isnull(tari.denumire, '') like '%'+@fltDenTara+'%'
and t.localitate like '%'+@fltLocalitate+'%'
and isnull(l.oras, t.localitate) like '%'+@fltDenLocalitate+'%'
and (@fltTipTert is null or isnull(it.zile_inc, 0) = @fltTipTert)
order by t.Denumire

select t1.tert, sum(sold) as sold from facturi,#terti100 t1 
where t1.tert=facturi.tert and subunitate=@subunitate and tip=0x54 group by t1.tert
select t1.tert, sum(sold) as sold from facturi,#terti100 t1 
where t1.tert=facturi.tert and subunitate=@subunitate and tip=0x46 group by t1.tert
   
select rtrim(t.tert) as tert, rtrim(t.denumire) as dentert, rtrim(t.cod_fiscal) as codfiscal, 
rtrim(t.localitate) as localitate, rtrim(isnull(l.oras, t.Localitate)) as denlocalitate, 
rtrim(case when isnull(it.zile_inc, 0)=0 then t.judet else '' end) as judet, rtrim(isnull(j.denumire, t.judet)) as denjudet, 
rtrim(case when isnull(it.zile_inc, 0)>0 then t.judet else '' end) as tara, rtrim(isnull(tari.denumire, '')) as dentara, 
rtrim(t.adresa) as adresa, 
rtrim(case when @AdrComp=1 then left(t.adresa, 30) else '' end) as strada,
rtrim(case when @AdrComp=1 then substring(t.adresa, 31, 8) else '' end) as numar,
rtrim(case when @AdrComp=1 then substring(t.adresa, 39, 6) else '' end) as bloc,
rtrim(case when @AdrComp=1 then substring(t.adresa, 45, 5) else '' end) as scara,
rtrim(case when @AdrComp=1 then substring(t.adresa, 50, 3) else '' end) as apartament,
rtrim(case when @AdrComp=1 then substring(t.adresa, 53, 8) else '' end) as codpostal,
rtrim(telefon_fax) as telefonfax, 
rtrim(t.banca) as banca, rtrim(isnull(b.denumire, '')) as denbanca, rtrim(t.cont_in_banca) as continbanca, 
convert(int, t.tert_extern) as decontarivaluta, rtrim(t.grupa) as grupa, rtrim(isnull(g.denumire, '')) as dengrupa, 
rtrim(t.cont_ca_furnizor) as contfurn, rtrim(isnull(cf.denumire_cont, '')) as dencontfurn, 
rtrim(t.cont_ca_beneficiar) as contben, rtrim(isnull(cb.denumire_cont, '')) as dencontben, 
convert(char(10), (case when t.sold_ca_furnizor<=693961 then '01/01/1901' when t.sold_ca_furnizor>1000000 then '12/31/2999' else dateadd(d, t.sold_ca_furnizor-693961, '01/01/1901') end), 101) as datatert,
convert(int, t.sold_ca_beneficiar) as categpret, rtrim(isnull(categpret.denumire, '')) as dencategpret,
convert(decimal(14, 2), t.sold_maxim_ca_beneficiar) as soldmaxben, convert(decimal(7, 2), t.disccount_acordat) as discount, 
convert(int, isnull(it.sold_ben, 0)) as termenlivrare, convert(int, isnull(it.discount, 0)) as termenscadenta, 
rtrim(isnull(it.nume_delegat, '')) as reprezentant, rtrim(isnull(it.eliberat, '')) as functiereprezentant, 
rtrim(isnull(it.loc_munca, '')) as lm, rtrim(isnull(lm.denumire, '')) as denlm,
rtrim(isnull(it.descriere, '')) as responsabil, rtrim(isnull(p.nume, '')) as denresponsabil,
rtrim(isnull(it.cont_in_banca2, '')) as info1, rtrim(isnull(it.cont_in_banca3, '')) as info2, rtrim(isnull(it.observatii, '')) as info3, 
rtrim(isnull(it.banca3, '')) as nrordreg, isnull(it.zile_inc, 0) as tiptert,
(case when isnull(it.grupa13, '')='1' then 1 else 0 end) as neplatitortva,
isnull(it.indicator, 0) as nomspec,
convert(decimal(13, 2), isnull(ff.sold, 0)) as soldfurn, convert(decimal(13, 2), isnull(fb.sold, 0)) as soldben, 
(case when isnull(ff.sold, 0)=0 and isnull(fb.sold, 0)=0 then '#808080' -- fara sold
	when exists(select 1 from proprietati where Cod_proprietate='CI8' and tip='TERT' and valoare='42' and cod=t.Tert) then'#0000FF' 
	when exists(select 1 from proprietati where Cod_proprietate='CI8' and tip='TERT' and valoare='43' and cod=t.Tert) then'#FF0000' 
	else '#000000' end)  as culoare 
from terti t   
inner join #terti100 t1 on t.Tert=t1.tert
left join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
left join judete j on isnull(it.zile_inc, 0)=0 and j.cod_judet=t.judet
left join tari on isnull(it.zile_inc, 0)>0 and tari.cod_tara=t.judet
left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
left join bancibnr b on b.cod=t.banca
left join gterti g on t.grupa=g.grupa
left join conturi cf on cf.subunitate=t.subunitate and cf.cont=t.cont_ca_furnizor
left join conturi cb on cb.subunitate=t.subunitate and cb.cont=t.cont_ca_beneficiar
left join categpret on categpret.categorie=t.sold_ca_beneficiar
left join lm on lm.cod=it.loc_munca
left join personal p on p.marca=it.descriere
left join #ff ff on ff.tert=t.tert
left join #fb fb on fb.tert=t.tert
where t.subunitate=@subunitate 
order by t.Denumire
for xml raw

drop table #fb
drop table #ff
drop table #terti100
end
