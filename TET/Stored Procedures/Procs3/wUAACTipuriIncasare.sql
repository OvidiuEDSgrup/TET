/****** Object:  StoredProcedure [dbo].[wUAACTipuriIncasare]    Script Date: 01/05/2011 23:41:36 ******/
--***
create PROCEDURE  [dbo].[wUAACTipuriIncasare] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACTipuriIncasareSP' and type='P')      
	exec wUAACTipuriIncasareSP @sesiune,@parXML      
else      
begin
declare  @searchText varchar(80),@utilizator char(10), @userASiS varchar(20)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') 		
set @searchText=REPLACE(@searchText, ' ', '%')

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select top 100 rtrim(id) as cod, rtrim(Denumire) as denumire,RTRIM(cont_specific) as info
from Tipuri_de_incasare
    left outer join LMFiltrare lu on lu.utilizator=@utilizator and loc_de_munca=lu.cod
where (id like @searchText + '%' or denumire like '%' + @searchText + '%')
  and (@lista_lm=0 or lu.cod is not null)
order by rtrim(id)  
for xml raw
end
