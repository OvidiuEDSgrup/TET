--***

CREATE procedure wAreDrepturi (@sesiune varchar(50),@parXML XML)
as
 declare @iDoc int EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
 
declare @utilizator varchar(200)
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
IF @utilizator IS NULL
	RETURN -1

select drept,min(isnull(are_drept,'nu')) as are_drept from 
(
select rtrim(du.drept) as drept,(case when du.id is null then 'nu' else 'da' end) as are_drept from 
	dreptutiliz du 
inner join utilizatori u on u.id=du.id and rtrim(u.observatii)=@utilizator
inner join OPENXML(@iDoc, '/*/*') WITH  (searchText varchar(80) '@searchText') filtre
			on du.drept=filtre.searchText
where du.tip='U'
union all 
select rtrim(du.drept) as drept,(case when du.id is null then 'nu' else 'da' end) as are_drept from 
	dreptutiliz du
inner join gruputiliz g on g.id_grup=du.id
inner join utilizatori u on u.id=g.id_utilizator and rtrim(u.observatii)=@utilizator
inner join OPENXML(@iDoc, '/*/*') WITH  (searchText varchar(80) '@searchText') filtre
			on du.drept=filtre.searchText
where du.tip='G'
union all 
select rtrim(filtre.searchtext),'da' from 
		OPENXML(@iDoc, '/*/*') WITH  (searchText varchar(80) '@searchText') filtre where 
exists(select 1 from dreptutiliz du
inner join utilizatori u on u.id=du.id and rtrim(u.observatii)=@utilizator
	where du.tip='U' and du.drept='ISPISI')
or exists(select 1 from dreptutiliz du
	inner join gruputiliz g on g.id_grup=du.id
	inner join utilizatori u on u.id=du.id and rtrim(u.observatii)=@utilizator
	where du.tip='G' and du.drept='ISPISI')
) a group by drept
order by rtrim(drept) for xml raw

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
