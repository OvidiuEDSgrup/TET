--***  
/* afisaza comenzi finalizate, pentru facturare. */
CREATE procedure [dbo].[wmComandaDeFacturat] @sesiune varchar(50), @parXML xml as  
	
set transaction isolation level READ UNCOMMITTED  
if exists(select * from sysobjects where name='wmComandaDeFacturatSP' and type='P')
begin
	exec wmComandaDeFacturatSP @sesiune, @parXML 
	return 0
end

declare @utilizator varchar(100), @tert varchar(30), @xmlFinal xml, @linieXML xml, @facturaDeIncasat varchar(100), 
		@msgEroare varchar(500), @idpunctlivrare varchar(100), @punctlivrare varchar(100), @subunitate varchar(30), @stareBkFacturabil varchar(30),
		@comanda varchar(50), @discountMinim decimal(12,2), @discountMaxim decimal(12,2), @pasDiscount decimal(12,2),
		@discount decimal(12,2), @rasp varchar(max)
		
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 
if @utilizator is null
	return -1

select	@comanda=@parXML.value('(/row/@wmIaComenziDeFacturat.cod)[1]','varchar(100)')
		
-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

-- citire date din par
select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @subunitate end),
		@stareBkFacturabil=(case when Parametru='STBKFACT' then rtrim(Val_alfanumerica) else @stareBkFacturabil end)
from par
where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru = 'STBKFACT')

-- citesc datele de numeric stepper pentru discount
exec wmIaDiscountAgent @sesiune=@sesiune, @discountMinim=@discountMinim output, @discountMaxim=@discountMaxim output, @pasDiscount=@pasDiscount output

-- verific daca starea comenzii = 'facturabil' - daca ajunge aici si comanda are alta stare(de ex. a facturat-o deja), dau back
if not exists (select 1 from con c where c.subunitate=@subunitate and c.tip='BK' and c.contract=@comanda and c.Tert=@tert and c.Punct_livrare=@idpunctlivrare)
begin
	select 'back(1)' actiune for xml raw,Root('Mesaje')   
	return 0
end


set @rasp='<Date>'+CHAR(13)+
	-- linie facturare
	isnull((select '<FacturareComanda>' cod, '<Facturare comanda>' denumire, 
		(select 'Total:'+(rtrim(convert(decimal(12,2),sum(pc.Cant_aprobata*pc.Pret*(1-pc.discount/100))))+' RON')
		from pozcon pc where pc.Subunitate=@subunitate and pc.Tip='BK' and pc.Contract=@comanda and pc.Tert=@tert) info,
		'0x0000ff' as culoare, 'refresh' actiune, 'C' as tipdetalii
	for xml raw),'')+CHAR(13)+
	
	-- linie cod nou
	(select '<CodNou>' cod, '<Adauga cod>' denumire, 'C' as tipdetalii,
	'0x0000ff' as culoare
	for xml raw)+CHAR(13)+
	
	--linii cu produse
	isnull((select rtrim(pc.cod) as cod, rtrim(n.Denumire) as denumire,   
		LTRIM(convert(char(10),(convert(decimal(12,2),pc.Cant_aprobata))))+' '+n.um+'*'  
			+RTRIM(convert(char(20),(convert(decimal(12,2),pc.Pret))))+' LEI'+  
		(case when pc.discount<>0 then '(-'+LTRIM(str(convert(decimal(12,2),pc.discount)))+'%)' else '' end)
		as info, 
		convert(decimal(12,3),pc.Cant_aprobata) as cantitate, convert(decimal(12,3),pc.pret) as pret, convert(decimal(12,2),pc.discount) as discount,
		'D' as tipdetalii,@discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas
	from pozcon pc  
	left outer join nomencl n on pc.Cod=n.Cod  
	where pc.Subunitate=@subunitate and pc.Tip='BK' and pc.Contract=@comanda and pc.Tert=@tert
	for xml raw),'')+CHAR(13)

	+'</Date>'
	
select CONVERT(xml, @rasp)

select 'Facturare comanda '+@comanda as titlu, 'wmComandaDeFacturatHandler' as detalii,0 as areSearch,
	'D' as tipdetalii, 
	(select datafield as '@datafield',nume as '@nume',tipobiect as '@tipobiect',latime as '@latime',modificabil as '@modificabil'  
	from webConfigForm where tipmacheta='M' and meniu='MD' and vizibil=1   
	order by ordine
	for xml path('row'), type) as 'form'
for xml raw,Root('Mesaje')   

--select * from tmp_facturi_de_listat
