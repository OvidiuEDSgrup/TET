--***
create procedure wACContracte @sesiune varchar(50), @parXML XML
as

if exists(select * from sysobjects where name='wACContracteSP' and type='P')      
	exec wACContracteSP @sesiune, @parXML
else      
begin
	declare @tip varchar(2), @searchText varchar(80), @tipContr varchar(2),@tert varchar(20),@meniu varchar(2),
		@raport varchar(1000), @benef varchar(1), @labelAC varchar(100)

	select	@raport=ISNULL(@parXML.value('(/row/@raport)[1]', 'varchar(20)'), ''),
			@benef=@parXML.value('(/row/@benef)[1]', 'varchar(20)'),
			@labelAC=@parXML.value('(/row/@Label)[1]', 'varchar(100)')	--> cu labelAC ma asigur ca este vorba despre contracte si nu despre comenzi in ceea ce priveste rapoartele
	select @searchText=replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ','%'),
		@tip=(case when @meniu is null and @raport is not null and @labelAC like 'con%' then 
					(case when @benef='F' then 'FA' when @benef='B' then 'BF' else 'C' end)
						--> daca este autocomplete pentru  raport poate fi pentru beneficiari/furnizori ('BF'/'FA') sau pentru ambele variante ('C')
					else ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') end),
		@meniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''),
		@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), ''),	--> varianta default pentru luarea tertului
		@tert=ISNULL(@parXML.value('(/row/@cTert)[1]', 'varchar(20)'), @tert)	--> exista rapoarte pe contracte care au ca parametru de filtrare cTert pentru terti

	set @tipContr=(case when @meniu in ('SP','YZ') then 'BF' when @tip in ('BK','PD','BF') then 'BF'  
		when @tip in ('FC','FA') then 'FA' when @tip in ('AP', 'AS', 'TE') then 'BK' else 'FC' end)

	select rtrim(c.contract) as cod, 
		(case when c.explicatii='' 
			then case when tip in ('BF','FA') then 'Contr. nr. '+RTRIM(c.Contract)+' - ' else 'Com. pt. ' end+rtrim(case when c.tert='' then g.Denumire_gestiune else t.Denumire end)+' din '+rtrim(convert(char(10),c.Data,103)) 
			else rtrim(c.explicatii) end) as denumire, 
		rtrim(case when c.tert='' then c.cod_dobanda else c.tert end)+ (case when @meniu='YW' then ' ->'+c.Tip else '' end) as info
	from con c 
		left outer join gestiuni g on g.Subunitate=c.Subunitate and g.Cod_gestiune=c.Cod_dobanda 
		left outer join terti t on t.Subunitate=c.Subunitate and  t.Tert=c.Tert 
	where (c.tip=@tipContr or @meniu='YW' or @tip='C' and c.tip in ('BF','FA'))-->in cazul operatiei de refacere sa aduca toate tipurile de contracte/comenzi 
		and ((rtrim(c.contract) like @searchText+'%' or rtrim(c.explicatii) like '%'+@searchText+'%') 
			or (rtrim(case when c.tert='' then g.Denumire_gestiune else t.Denumire end) like '%'+@searchText+'%'))
		and ((c.Tert=@tert or isnull(@tert,'')='' ))--or @tip<>'PD')
	for xml raw
end
