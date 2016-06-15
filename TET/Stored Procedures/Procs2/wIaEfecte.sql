--***
create procedure wIaEfecte @sesiune varchar(50), @parXML xml
as

declare @Sub char(9), @userASiS varchar(10), @lista_lm bit, @lista_conturi bit,
	@tip varchar(2), @cont varchar(40), @fcont varchar(40), @data_jos datetime, @data_sus datetime, @data datetime, 
	@tplati_jos float, @tplati_sus float, @tinc_jos float, @tinc_sus float, @fnume varchar(50),
	@tert varchar(13),@efect varchar(20),@tipefect varchar(1),@f_efect varchar(13),@f_tert varchar(50)
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
select @lista_lm=dbo.f_arelmfiltru(@userASiS), @lista_conturi=0
select @lista_conturi=1
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CONTPLIN' and valoare<>''

select @tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@cont = isnull(@parXML.value('(/row/@cont)[1]', 'varchar(40)'), ''), 
	@tert = ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''), 
	@efect = ISNULL(@parXML.value('(/row/@efect)[1]','varchar(20)'), ''),
	@f_efect = ISNULL(@parXML.value('(/row/@f_efect)[1]','varchar(20)'), ''),
	@f_tert = ISNULL(@parXML.value('(/row/@f_tert)[1]', 'varchar(13)'), ''), 
	@fcont = isnull(@parXML.value('(/row/@f_cont)[1]', 'varchar(40)'), ''), 
	@tipefect = ISNULL(@parXML.value('(/row/@tipefect)[1]','varchar(1)'), ''), 
	@data_jos = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1901'),
	@data_sus = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '01/01/1901'), 
	@data = @parXML.value('(/row/@data)[1]', 'datetime'), 
	@tplati_jos = isnull(@parXML.value('(/row/@f_tplatijos)[1]', 'float'), -99999999999),
	@tplati_sus = isnull(@parXML.value('(/row/@f_tplatisus)[1]', 'float'), 99999999999), 
	@tinc_jos = isnull(@parXML.value('(/row/@f_tincjos)[1]', 'float'), -99999999999),
	@tinc_sus = isnull(@parXML.value('(/row/@f_tincsus)[1]', 'float'), 99999999999)

select top 100 rtrim(p.subunitate) as subunitate, @tip as tip, 
	rtrim(p.cont) as cont, rtrim(max(isnull(c.denumire_cont, ''))) as dencont, 
	convert(char(10), p.data, 101) as data, rtrim(max(p.valuta)) as valuta, convert(decimal(15,4), max(p.curs)) as curs, 
	rtrim(max(p.tert)) as tert, rtrim(max(isnull(t.denumire, ''))) as dentert, 
	rtrim(max(isnull(p.efect, p.numar))) as efect, 
	sum(convert(decimal(15,2), case when LEFT(p.Plata_incasare,1)=ef.Tip then p.suma else 0 end)) as valoare, 
	sum(case when LEFT(p.Plata_incasare,1)=ef.Tip then 1 else 0 end) as numarpozitii,
--	comentat partea de mai jos. In principiu campurile din detalii se citesc dinspre frame. 
/*	isnull(isnull(convert(CHAR(10), max(p.detalii.value('(/row/@dataefect)[1]','datetime')), 101), convert(CHAR(10), max(p.data), 101)), '01/01/1901') AS dataefect, 
	isnull(max(p.detalii.value('(/row/@contbanca)[1]','varchar(35)')), '') AS contbanca, 
	rtrim(isnull(max(p.detalii.value('(/row/@serieefect)[1]','varchar(20)')),'')) as serieefect, rtrim(isnull(max(p.detalii.value('(/row/@numarefect)[1]','varchar(20)')),'')) as numarefect,
	rtrim(isnull(max(p.detalii.value('(/row/@contbctert)[1]','varchar(20)')),'')) as contbctert, rtrim(ISNULL(max(p.detalii.value('(/row/@bancatert)[1]','varchar(20)')),'')) as bancatert,*/
	rtrim(ISNULL(max(ban.Denumire),''))+' - ' +rtrim(ISNULL(max(ban.filiala),'')) as denbancatert,
	case when RTRIM(max(ef.tip))='P' then 'De platit' else 'De incasat' end as dentipefect, RTRIM(max(ef.tip)) as tipefect,
	convert(xml,max(convert(varchar(max),p.detalii))) as detalii, 
	--pentru tabul de inregistrari contabile:
	'PI' tipdocument,rtrim(p.Cont) as 'nrdocument'
from pozplin p
	inner join efecte ef on ef.Subunitate=@Sub and ef.Cont=p.Cont and ef.Nr_efect=p.efect and ef.Tert=p.Tert /*and ef.Data=p.Data*/ and ef.Tip=LEFT(p.Plata_incasare,1)
	left outer join conturi c on c.subunitate = p.subunitate and c.cont = p.cont 	
	left outer join terti t on t.subunitate=p.subunitate and t.tert=p.tert
	LEFT OUTER JOIN bancibnr ban on p.detalii.value('(/row/@bancatert)[1]','varchar(20)')= ban.Cod
where p.subunitate=@Sub
	and (isnull(@tert,'')='' or p.Tert=@tert)
	and (isnull(@efect,'')='' or p.efect=@efect)
	and (isnull(@tipefect,'')='' or @tipefect=ef.Tip)
	and (@data is null or p.data=@data) 
	--and (isnull(c.sold_credit, 0)=8)-->numai efecte
	and (@cont='' or p.cont=@cont) and p.cont like @fcont + '%'
	and (@f_efect='' or ef.Nr_efect like @f_efect+'%')
	and (@f_tert='' or ef.Tert like @f_tert+'%' or t.Denumire like '%'+@f_tert+'%')	
	and p.data between @data_jos and (case when @data_sus<='01/01/1901' then '12/31/2999' else @data_sus end)
	and (@lista_lm=0 or exists (select 1 from lmfiltrare lu where lu.utilizator=@userASiS and lu.cod=p.loc_de_munca))
	and (@lista_conturi=0 or exists (select 1 from proprietati lc where RTrim(p.cont) like RTrim(lc.valoare)+'%' and lc.tip='UTILIZATOR' and lc.cod=@userASiS and lc.cod_proprietate='CONTPLIN'))
group by p.subunitate,p.tert,isnull(p.efect, p.numar),ef.tip,p.data,p.Cont	
order by p.data desc  
for xml raw

if exists (select 1 from syscolumns sc, sysobjects so where so.id = sc.id and so.NAME = 'pozplin' and sc.NAME = 'detalii')
	select 1 areDetaliiXml for xml raw, root('Mesaje')

/*
sp_help efecte 
*/
