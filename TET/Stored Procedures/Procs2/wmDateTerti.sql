--***
CREATE procedure [dbo].[wmDateTerti] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDateTertiSP' and type='P')
begin
	exec wmDateTertiSP @sesiune, @parXML 
	return 0
end
set transaction isolation level READ UNCOMMITTED

declare @tert varchar(20),@cod varchar(20), @utilizator varchar(30), @idpunctlivrare varchar(30), @punctlivrare varchar(30),
		@subunitate varchar(100), @areFiltruLm bit

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return -1

select	@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
		@idPunctLivrare=@parXML.value('(/row/@pctliv)[1]','varchar(100)')

select	@punctlivrare=' - '+(select max(descriere) from infotert where rtrim(tert)=@tert and identificator=rtrim(@idpunctlivrare) 
								and subunitate=rtrim(@subunitate)),
		@cod=@parXML.value('(/row/@wmDetTerti.cod)[1]','varchar(100)')

select	@subunitate=rtrim(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru ='SUBPRO'

declare @lmFiltrate table(lm varchar(50))
insert into @lmFiltrate(lm)
select RTRIM(valoare)
from proprietati p
where p.Tip='UTILIZATOR' and cod=@utilizator and p.Cod_proprietate='LOCMUNCAF' and Valoare<>''

set @areFiltruLm = ISNULL((select MAX(1) from @lmFiltrate),0)

if @cod='SF' or @cod='SB'
begin
	select 'RM' as detaliu,rtrim(f.factura) as cod,
	'Factura: '+rtrim(f.factura)+' din '+convert(char(10),f.data,103) as denumire,
	'Val:'+LTRIM(convert(char(20),convert(money,f.valoare+f.TVA_11+f.TVA_22),1))+',Ach:'+LTRIM(convert(char(20),convert(money,achitat),1))
		+ isnull(' -> '+rtrim(it.descriere) + '('+rtrim(it.identificator)+')' ,'') as info
	from facturi f
		left join doc d on d.subunitate=f.subunitate and d.cod_tert=f.tert and d.factura=f.factura and d.data_facturii=f.data and d.tip ='AP'
		left join infotert it on it.tert=f.tert and it.subunitate=f.subunitate and it.identificator<>'' and it.identificator=d.gestiune_primitoare
	where 
	(@cod='SB' and f.tip=0x46 or @cod='SF' and f.tip=0x54) 
		and f.tert=@tert 
		and (d.gestiune_primitoare=@idPunctLivrare or isnull(@idPunctLivrare,'')='' or isnull(d.gestiune_primitoare,'')='')
		-- filtrul pe punct livrare din incfact nu cred ca merge bine... cand este timp ar trebui discutat.
		and ABS(sold)>0.009
	order by f.data
	for xml raw
end
if @cod='CM' 
begin
  select 'RM' as detaliu, rtrim(c.contract) as cod,
   'Comanda: '+rtrim(c.contract)+ ' din '+convert(char(10),c.data,103) as denumire,
   'Val:'+rtrim(convert(decimal(12,2),sum(pc.Cantitate*pc.Pret*(1-pc.discount/100)))) as info
   from con c
   left outer join pozcon pc on pc.subunitate=c.subunitate and pc.contract=c.contract and pc.tert=c.tert 
   where @cod='CM' and c.tert=@tert and c.stare=(select rtrim(val_alfanumerica) from par where tip_parametru='UC' and parametru='STAREBK1') and c.tip='BK' and c.responsabil=@utilizator
   group by c.Contract,c.data
   order by c.data
   for xml raw
end	
if @cod='CD' 
begin
-- print 'CD'
  exec wmIaComenziTert @sesiune, @parXML

 select 'wmScriuCantitate' as detalii,0 as areSearch, 'Comanda deschisa' as titlu 
 ,'D' as tipdetalii, dbo.f_wmIaForm('MD') form  
for xml raw,Root('Mesaje')  
  return
end	
if @cod='CF' 
begin
  select 'RM' as detaliu, rtrim(c.contract) as cod,
   'Comanda: '+rtrim(c.contract)+ ' din '+convert(char(10),c.data,103) as denumire,
   'Val:'+rtrim(convert(decimal(12,2),sum(pc.Cantitate*pc.Pret*(1-pc.discount/100)))) as info
   from con c
   left outer join pozcon pc on pc.subunitate=c.subunitate and pc.contract=c.contract and pc.tert=c.tert 
   where @cod='CF' and c.tert=@tert and c.stare=(select rtrim(val_alfanumerica) from par where tip_parametru='UC' and parametru='STAREBK6') and c.tip='BK'and c.responsabil=@utilizator
   group by c.Contract,c.data
   order by c.data
   for xml raw
end	
if @cod='CR' 
begin
  select 'CT' as detaliu, rtrim(c.contract) as cod,
   'Comanda: '+rtrim(c.contract)+ ' din '+convert(char(10),c.data,103) as denumire,
   'Val:'+rtrim(convert(decimal(12,2),sum(pc.Cantitate*pc.Pret*(1-pc.discount/100)))) as info
   from con c
   left outer join pozcon pc on pc.subunitate=c.subunitate and pc.contract=c.contract and pc.tert=c.tert 
   where @cod='CR' and c.tert=@tert and c.stare=(select rtrim(val_alfanumerica) from par where tip_parametru='UC' and parametru='STAREBK4') and c.tip='BK'and c.responsabil=@utilizator
   group by c.Contract,c.data
   order by c.data
   for xml raw
end	
if @cod='<NOU>' 
 exec wmIaComenziTert @sesiune, @parXML
if @cod='CR' 
begin
  select 'CT' as detaliu, rtrim(c.contract) as cod,
   'Comanda: '+rtrim(c.contract)+ ' din '+convert(char(10),c.data,103) as denumire,
   'Val:'+rtrim(convert(decimal(12,2),sum(pc.Cantitate*pc.Pret*(1-pc.discount/100)))) as info
   from con c
   left outer join pozcon pc on pc.subunitate=c.subunitate and pc.contract=c.contract and pc.tert=c.tert 
   where @cod='CR' and c.tert=@tert and c.stare=(select rtrim(val_alfanumerica) from par where tip_parametru='UC' and parametru='STAREBK4') and c.tip='BK'and c.responsabil=@utilizator
   group by c.Contract,c.data
   order by c.data
   for xml raw
end	
if @cod='PC' 
begin
	select rtrim(Identificator) as cod,RTRIM(it.Descriere) as denumire,
	RTRIM(it.Telefon_fax2) as info,
	'tel:'+RTRIM(it.Telefon_fax2) as actiune, rtrim(it.Descriere) as nume, rtrim(it.Telefon_fax2) as telefon, rtrim(it.e_mail) as email,
		 rtrim(it.observatii) as yahoomess, it.Identificator as id
	from infotert it
	where it.Subunitate='C1' and it.Tert=@tert
	union all 
	select '<NOU>' cod, '<Contact nou>' denumire, '' info, null actiune, 
		null, null, null, null, null
   for xml raw
   
   	select 
		'wmScriuPersoaneContact' as detalii, 0 as areSearch,'D' as tipdetalii,
		dbo.f_wmIaForm('CN') form
	for xml raw,Root('Mesaje')
	return 0
end	
	
select rtrim(denumire)+rtrim(isnull(@punctlivrare,'')) as titlu,0 as areSearch,
	(case when @cod='<NOU>' then 'wmDetComenziTert' 
		when @cod='PC' then 'wmDetPuncteLivrare' 
		else 'wmDocFacturi' end) as detalii
from terti where tert=@tert 
for xml raw,Root('Mesaje')
