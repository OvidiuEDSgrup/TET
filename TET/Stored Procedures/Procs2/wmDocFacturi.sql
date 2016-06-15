--***
CREATE procedure [dbo].[wmDocFacturi] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDocFacturiSP' and type='P')
begin
	exec wmDocFacturiSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @tert varchar(20),@cod varchar(20),@factura varchar(20), @subunitate varchar(9), @searchText varchar(20), @cValoare varchar(20),@titlu varchar(80),
	@utilizator varchar(50), @raspuns xml, @data datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

select	@cod=@parXML.value('(/row/@wmDetTerti.cod)[1]','varchar(100)'),
		@factura=isnull(@parXML.value('(/row/@wmDateTerti.cod)[1]','varchar(100)'),@parXML.value('(/row/@wmSituatieFacturiTerti.cod)[1]','varchar(100)')),
		@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
		@searchText=@parXML.value('(/row/@searchText)[1]','varchar(100)'),
		@searchText='%'+replace(@searchText,' ','%')+'%'

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
if @cod='ST' -- vine din situatii ultima luna
	set @cod='SB'
if @cod='SF' or @cod='SB'
begin
	select @cValoare=convert(varchar(20),convert(decimal(12,2),sum(p.cantitate*p.Pret_vanzare+p.TVA_deductibil))), @data=MAX(p.Data_facturii)
	from pozdoc p
	where p.Subunitate='1' and p.Tert=@tert and p.Factura=@factura
	
	set @titlu='Fact: '+rtrim(@factura)+', Val: '+@cValoare
	
	set @raspuns='<Date>'+
		(case when @cod='SB' then 
			(select '1' toateAtr, '<Retipareste factura>' denumire, @factura numar, 'wmTiparesteFactura' procdetalii, '#000000' culoare,
				CONVERT(varchar(10), @data, 120) data 
			for xml raw)
		else '' end)
		+
		isnull((select rtrim(n.Denumire) as denumire,
		convert(varchar(20),convert(decimal(12,2),p.cantitate))+' '+n.UM+' x '+convert(varchar(20),convert(decimal(12,2),p.pret_vanzare))+'+TVA = '+
			CONVERT(varchar(20),CONVERT(money,p.Cantitate*p.pret_vanzare+p.TVA_deductibil),1) as info
		from pozdoc p
		inner join nomencl n on p.cod=n.cod
		where p.Subunitate=@subunitate and p.Tert=@tert and p.Factura=@factura
		for xml raw
		),'')+'</Date>'
	select convert(xml,@raspuns)
end
if @cod in ('CM','CD') 
begin
	set @titlu='Comanda:'+@factura
	select 1 as ord,'<FACTUREAZA>' as cod,'<FACTUREAZA>' as denumire,'' as info,
	'0x000000' as culoare
	union all
	select top 100 2 as ord,rtrim(pc.cod) as cod, 
	rtrim(n.Denumire) as denumire, 
	convert(varchar(20),convert(decimal(12,2),pc.Cantitate))+' '+n.um+'*'
		+convert(varchar(20),convert(decimal(12,2),pc.Pret))+' LEI'+
		(case when pc.discount<>0 then '(-'+convert(varchar(20),convert(decimal(12,2),pc.discount))+'%)' else '' end)
		as info,'0xffffff' as culoare
	from pozcon pc
	inner join con c on c.subunitate=pc.subunitate and c.contract=pc.contract and c.tert=pc.tert and c.Data=pc.Data
	left outer join nomencl n on pc.Cod=n.Cod
	where	pc.Subunitate=@subunitate and pc.Tip='BK' and pc.Contract=@factura and pc.tert=@tert and 
			(n.denumire like @searchText or @searchtext='')
	for xml raw
end


/*

select 'SF' as detaliu,
'Sold furnizor '+convert(varchar(20),convert(money,SUM(ff.sold),2))+' RON' as denumire
from facturi ff
where ff.tip=0x46 and ff.tert=@cod
union all 
select 'SB' as detaliu,
'Sold beneficiar '+convert(varchar(20),convert(money,SUM(ff.sold),2))+' RON' as denumire
from facturi ff
where ff.tip=0x54 and ff.tert=@cod
union all
select 'CM' as detaliu,
'Comenzi neonorate: '+ltrim(str(COUNT(*))) as denumire
from con where tert=@cod and stare='1'
for xml raw
*/
select 
	@titlu as titlu,0 as areSearch
from terti where tert=@tert
for xml raw,Root('Mesaje')
