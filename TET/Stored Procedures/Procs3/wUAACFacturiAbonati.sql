/****** Object:  StoredProcedure [dbo].[wUAACAbonati]    Script Date: 01/05/2011 23:38:12 ******/
--***
create PROCEDURE [dbo].[wUAACFacturiAbonati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACFacturiAbonatiSP' and type='P')      
	exec wUAACFacturiAbonatiSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@abonat varchar(13),@utilizator char(10), @userASiS varchar(20)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @abonat=ISNULL(@parXML.value('(/row/@abonat)[1]', 'varchar(13)'), '')
	   
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------	    
		
set @searchText=REPLACE(@searchText, ' ', '%')
select top 100 a.Id_factura as cod, rtrim(a.Factura)+' din data de: '+convert(char(10),a.Data,101)+', Sold: '+convert(varchar,f.sold)as denumire,
               'Sold: '+convert(varchar,f.sold) as info
from AntetFactAbon a 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
, FactAbon f      
                                       
where (a.Factura like  @searchText + '%' or a.Id_factura like  @searchText + '%')
  and (rtrim(f.abonat)=@abonat or @abonat='')
  and a.id_factura=f.id_factura
  and f.sold>0.001
  and (@lista_lm=0 or lu.cod is not null)
order by a.Factura  
for xml raw
end
--select * from antetfactabon	select * from uafactabon
--select * from uacon where abonat='1001034-E'
--select sum (sold) from UAFactAbon where abonat='1001034-E'
