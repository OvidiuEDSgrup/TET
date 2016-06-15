create procedure [dbo].[wACAngajamenteBugetare] @sesiune varchar(50), @parXML XML
as
begin
	declare @searchText varchar(8),@data_ang_bug datetime,@data_sus_ang_bug datetime,@data_ordonantare datetime, @utilizator varchar(20),
		@new_indbug varchar(20),@indbug varchar(20),@subtip varchar(2),@compartiment varchar(20),@tip varchar(2)

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1

	declare @lista_lm int
	set @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA'
  
    select 
		@searchText = isnull(@parXML.value('(/row/@searchText)[1]','varchar(20)'),''),
		@searchText = '%'+replace(@searchText,' ','%')+'%',
		@searchText = replace(@searchText,'.',''),
		@compartiment = isnull(@parXML.value('(/row/@compartiment)[1]','varchar(20)'),''),
		@data_ang_bug = isnull(@parXML.value('(/row/@data_ang_bug)[1]','datetime'),'1901-01-01'),
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@subtip = isnull(@parXML.value('(/row/@subtip)[1]','varchar(2)'),''),
		@data_ordonantare = isnull(@parXML.value('(/row/@data_ordonantare)[1]','datetime'),'1901-01-01')
	  

	select rtrim(a.cod)+'|'+convert(varchar, a.data, 101) as cod,a.denumire+' -> Suma disp:'+convert(varchar,a.info) as denumire,a.text+convert(varchar,a.info) as info from
		(select rtrim(ltrim(ab.numar)) as cod,
			'Ang.bug: '+rtrim(ltrim(ab.numar))+', ind: '+
       		isnull(substring(indicator,1,2),'  ')+'.'+isnull(substring(indicator,3,2),'  ')+'.'+isnull(substring(indicator,5,2),'  ')+'.'+isnull(substring(indicator,7,2),'  ')+'.'
			+isnull(substring(indicator,9,2),'  ')+'.'+isnull(substring(indicator,11,2),'  ')+'.'+isnull(substring(indicator,13,2),'  ')+' - '+rtrim(ltrim(i.denumire)) as denumire,
			' din '+convert(varchar, data, 101)+', Suma disponibila: 'as text,
			convert(decimal(12,3),ab.suma-
								   isnull((select sum(suma) from ordonantari where numar_ang_bug=ab.numar and data_ang_bug=ab.data),0)) as info,convert(varchar, data, 101) as data
		from angbug ab
		inner join indbug i on ab.indicator=i.indbug and i.grup=0 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and ab.Loc_de_munca =lu.cod
		where 
			ab.stare in('6')
			and year(ab.data)=year(@data_ordonantare)
			and ab.data<=@data_ordonantare
			and ab.Suma>0.1
			and (@lista_lm=0 or lu.cod is not null)
			and ((ab.Loc_de_munca like SUBSTRING(@compartiment,1,1) or ISNULL(@compartiment,'')='') and @tip='AL' and @subtip='')
			and (((i.denumire like '%'+replace(@searchText,' ','%')+'%') or (i.indbug like @searchText+'%') or (ab.numar like @searchText+'%')) or (@searchText=' ') )
			) a
	  
	where a.info>0.1	   
	for xml raw
end
