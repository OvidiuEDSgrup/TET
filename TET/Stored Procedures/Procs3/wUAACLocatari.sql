/****** Object:  StoredProcedure [dbo].[wUAACNomenclAbon]    Script Date: 01/05/2011 23:40:09 ******/
--***
create PROCEDURE  [dbo].[wUAACLocatari] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACLocatariSP' and type='P')      
	exec wUAACLocatariSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@tip varchar(2),@id_contract int,@utilizator char(10), @userASiS varchar(20)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @tip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '') ,
	   @id_contract=ISNULL(@parXML.value('(/row/@id_contract)[1]', 'int'), '') 	
		
set @searchText=REPLACE(@searchText, ' ', '%')

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------
select top 100 rtrim(l.locatar) as cod, rtrim(l.nume) as denumire
	from locatari l --left outer join LMFiltrare lu on lu.utilizator=@utilizator and l.loc_de_munca=lu.cod			   
	where (l.Locatar like @searchText + '%' or l.nume like '%' + @searchText + '%')
		 and l.Id_contract=@id_contract
		 --and (@lista_lm=0 or lu.cod is not null)
	order by rtrim(l.nume)  
for xml raw
end
