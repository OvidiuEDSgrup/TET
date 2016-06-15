--***
CREATE procedure wACMasini @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACMasiniSP' and type='P')      
	exec wMasiniSP @sesiune,@parXML      
else      
begin

	declare @subunitate varchar(9), @searchText varchar(80), @tip char(2), @tip_activitate char(1)

	select	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
			@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'char(2)'), '')
	if @tip='FU' set @tip='FL'
	if @tip='IU' set @tip='FI'
	--
	set @searchText=REPLACE(@searchText, ' ', '%')
	if @tip not in ('FP','FL')
		set @tip_activitate=''
	else 
		set @tip_activitate=(case when @tip='RP' then 'L' else SUBSTRING(@tip,2,1) end)
	/*pt FP=>P;FA=>A;de adaugat altele la nevoie*/

	select top 100 
	RTRIM(m.cod_masina) as cod, 
	RTRIM(m.denumire) as denumire,
	RTRIM(t.Denumire) as info
	from masini m
		inner join grupemasini g on m.grupa=g.Grupa
		inner join tipmasini t on g.tip_masina=t.Cod 
		
	where (m.denumire like '%'+@searchText+'%' or m.cod_masina like @searchtext+'%') 
		and (@tip_activitate='' or t.Tip_activitate= @tip_activitate)
	order by patindex('%'+@searchText+'%',t.Denumire),1
	for xml raw

end
