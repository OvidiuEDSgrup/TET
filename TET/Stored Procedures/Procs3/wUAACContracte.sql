/****** Object:  StoredProcedure [dbo].[wUAACContracte]    Script Date: 01/05/2011 22:55:22 ******/
--***
create PROCEDURE [dbo].[wUAACContracte] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACContracteSP' and type='P')      
	exec wUAACContracteSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@utilizator char(10), @userASiS varchar(20)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') 
		
set @searchText=REPLACE(@searchText, ' ', '%')

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select top 100 rtrim(u.Id_contract) as cod, rtrim(u.Contract)+' - '+rtrim(a.Denumire) as denumire
from UAcon u left outer join abonati a on a.abonat=u.abonat
			 left outer join LMFiltrare lu on lu.utilizator=@utilizator and u.Loc_de_munca=lu.cod
where (u.Contract like @searchText + '%' or a.denumire like '%' + @searchText + '%')
  and (@lista_lm=0 or lu.cod is not null)
order by rtrim(Contract)  
for xml raw
end

--select * from UAcon
--sp_help uacon
