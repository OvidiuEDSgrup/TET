/****** Object:  StoredProcedure [dbo].[wUAACNomenclAbon]    Script Date: 01/05/2011 23:40:09 ******/
--***
create PROCEDURE  [dbo].[wUAACNomenclAbon] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACNomenclAbonSP' and type='P')      
	exec wUAACNomenclAbonSP @sesiune,@parXML      
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
if @tip='DL' 
begin
	select top 100 rtrim(a.cod) as cod, rtrim(a.Denumire) as denumire, 
		'UM: '+RTRIM(UM)+', Tarif: '+CONVERT(varchar,a.tarif) as info 
	from NomenclAbon a left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
	                   inner join UApozcon p on a.cod=p.cod
					   
	where (a.cod like @searchText + '%' or a.denumire like '%' + @searchText + '%')
		 and p.Id_contract=@id_contract
		 and (@lista_lm=0 or lu.cod is not null)
	order by rtrim(a.denumire)  
	for xml raw
	end
else
	begin	
		select top 100 rtrim(a.cod) as cod, rtrim(a.Denumire) as denumire, 
			'UM: '+RTRIM(UM)+', Tarif: '+CONVERT(varchar,tarif) as info 
			from NomenclAbon a
						left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
			where (a.cod like @searchText + '%' or a.denumire like '%' + @searchText + '%')
			  and (@lista_lm=0 or lu.cod is not null)
			order by rtrim(a.denumire)  
			for xml raw
	end		
end
--select * from nomenclabon
