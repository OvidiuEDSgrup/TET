/****** Object:  StoredProcedure [dbo].[wUAACCasieri]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE  [dbo].[wUAACCasieri]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACCasieriSP' and type='P')      
	exec wUAACCasieriSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@tip varchar(2),@utilizator char(10), @userASiS varchar(20)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

set @searchText=REPLACE(@searchText, ' ', '%')

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

/*if @tip in('IT')
	 
	select rtrim(Cod_casier) as cod, rtrim(Casier) as denumire
	from casieri
	where (Cod_casier like @searchText + '%' or Casier like '%' + @searchText + '%')
	  and Cod_casier not in (select id from utilizatori)
	order by rtrim(Cod_casier) 
else	*/
	select rtrim(Cod_casier) as cod, rtrim(Casier) as denumire
	from casieri 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and loc_de_munca=lu.cod
	where (Cod_casier like @searchText + '%' or Casier like '%' + @searchText + '%')
	  and (@lista_lm=0 or lu.cod is not null)	
	order by rtrim(Cod_casier) 

for xml raw
end
