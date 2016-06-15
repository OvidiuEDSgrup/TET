--***
CREATE procedure wACInterventii @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wInterventiiSP' and type='P')      
	exec wInterventiiSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80), @tip char(2),@masina varchar(40)

	select	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
			@masina=@parXML.value('(/row/@masina)[1]', 'varchar(40)')
	set @searchText=REPLACE(@searchText, ' ', '%')
	 	
	select RTRIM(e.cod) as cod,
	       RTRIM(e.denumire) as denumire	
	from elemente e 
	
	where (e.denumire like '%'+@searchText+'%' or e.cod like @searchText+'%')
	       and e.tip='I' and (@masina is null or 
		   exists (select 1 from elemtipm et inner join grupemasini g on g.tip_masina=et.Tip_masina
											 inner join masini m on m.grupa=g.Grupa
					where e.Cod=et.Element and m.cod_masina=@masina)
	       )
	order by patindex('%'+@searchText+'%',e.Denumire),1
	for xml raw

end
