create procedure [dbo].[wIaPozGP] @sesiune varchar(50), @parXML xml    
as    
  
declare @subunitate char(9), @tip varchar(2), @tert varchar(20),@nrdoc varchar(20),@data datetime, @_cautare varchar(20),  
		@doc xml
select	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),    
		@tert=ISNULL(@parXML.value('(/row/ @tert)[1]', 'varchar(20)'), ''),    
		@nrdoc=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),  
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),  
		@_cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(25)'),'')    


set @doc=  
(select RTRIM(max(gp.numar_document)) as numar, 
		rtrim(max(gp.iban_beneficiar)) as benfiban,rtrim(max(bnr.Denumire)) as benfbanca,  
		rtrim(max(bnr.Cod)) as benfcodbanca, convert(varchar(20),max(gp.Data),101) as data,  
		RTRIM(max(gp.cont_platitor)) as contplatitor, RTRIM(max(t.tert)) as tert,  rtrim(max(t.Denumire)) as dentert,  
		convert(decimal(10,2),sum(isnull(gp.suma_platita,''))) as valoare,  convert(decimal(10,2),sum(gp.val1)) as sumapl, 
	(select   
		  RTRIM(MAX(gp1.numar_document)) as numar, (case when max(gp1.stare)=0 then 'G' when max(gp1.stare)=1 then 'F' else '' end)  as subtip,  
		  convert(varchar(20),MAX(gp1.DATA),101) as data,
		  RTRIM(MAX(isnull(gp1.tert,''))) as tert,  max(isnull(rtrim(gp1.val3),0)) as platiincasari,
		  (case when max(isnull(rtrim(gp1.val3),0))=1 and max(isnull(gp1.stare,0))=1 then 'Va fi generata in Plati incasari' 
				when max(isnull(rtrim(gp1.val3),0))=1 and max(isnull(gp1.stare,0))=2 then 'Generata in plati incasari'
				when max(isnull(rtrim(gp1.val3),0))=0 and max(isnull(gp1.stare,0))=1 then 'Fisier OP Generat'
				when max(isnull(rtrim(gp1.val3),0))=0 and max(isnull(gp1.stare,0))=0 then 'Operabil'
							else '' end) as stareFactura,
		  (case when max(gp1.val1)>0  and max(isnull(gp.iban_beneficiar,'')) <>'' and max(isnull(gp.Banca_beneficiar,''))<>'' and max(isnull(gp1.stare,0))=0 then 'green' 
				when max(isnull(gp1.stare,0))=1 then 'blue' when max(isnull(gp1.stare,0))=2 then 'gray'
				else 'black' end ) as culoare,   
		  RTRIM(max(isnull(gp1.numar_ordin,''))) as numarop, (case when max(gp1.element) in ('F','N') 
														then convert(varchar(20),max(gp1.Data1),101) else '' end) as datafacturii,   
		  (case when max(gp1.element)='F' then convert(varchar(20),max(gp1.data2),101) else '' end) as datascad,   
		  convert(varchar(20),max(gp1.Data3),101) as datapreluarii,   convert(decimal(10,2),max(gp1.suma_platita)) as valoare,  
		  (case when max(gp1.element) in ('F','N') then RTRIM(max(gp1.Factura)) else '' end) as factura,          
		  RTRIM(max(gp1.Detalii_plata)) as observatii, convert(decimal(10,2),max(gp1.val1)) as sumapl,
		  (case when convert(decimal(10,2),max(gp1.Val1))=0	then convert(decimal(10,2),max(gp1.suma_platita)) 
														else convert(decimal(10,2),max(gp1.val1))  end) as valfact
	from generareplati gp1  
	where	gp1.Numar_document=gp.Numar_document and 
			gp1.data=gp.Data and gp1.Tert=gp.Tert and gp1.tip=gp.tip /*and
			(case when abs(gp1.val1)>0.01 and isnull(gp1.IBAN_beneficiar,'')<>'' and isnull(gp1.Banca_beneficiar,'')<>'' then '@v' end) 
			like '%'+REPLACE(isnull(@_cautare,''),' ','%')+'%'  or '%'+REPLACE(isnull(@_cautare,''),' ','%')+'%'  =''  */
	GROUP BY factura
	for xml raw, type)         
	
from generareplati gp  
	left join terti t on t.Tert=gp.Tert  
	left join bancibnr bnr on bnr.Cod=gp.Banca_beneficiar
where gp.Numar_document=@nrdoc  
	and ((gp.factura like '%'+REPLACE(@_cautare,' ','%')+'%'   or '%'+REPLACE(@_cautare,' ','%')+'%'  ='')  
	or (t.denumire like '%'+REPLACE(@_cautare,' ','%')+'%'   or '%'+REPLACE(@_cautare,' ','%')+'%'  ='')  
	or (case when gp.val1>0 and gp.IBAN_beneficiar<>'' and gp.Banca_beneficiar<>'' then '@v' end) 
			like '%'+REPLACE(@_cautare,' ','%')+'%'  or '%'+REPLACE(@_cautare,' ','%')+'%'  ='')  
group by gp.numar_document,gp.data,gp.tert,gp.tip
order by tert
for xml raw, root('Ierarhie')  
)

if @doc is not null and @_cautare<>' ' 
	set @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')		
select @doc for xml path('Date')  
