create procedure wIaInventarSerii @sesiune varchar(50), @parXML xml 
as 
declare @f_serie varchar(20), @f_gestiune varchar(20), @f_tipgest varchar(20), @f_datajos datetime, @f_datasus datetime, @tip varchar(2)

select @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(22)'), ''),
       @f_serie=ISNULL(@parXML.value('(/row/@f_serie)[1]', 'varchar(20)'), ''),
	   @f_gestiune=ISNULL(@parXML.value('(/row/@f_gestiune)[1]', 'varchar(20)'), ''),
	   @f_tipgest=ISNULL(@parXML.value('(/row/@f_tipgest)[1]', 'varchar(20)'), ''),
	   @f_datajos=ISNULL(@parXML.value('(/row/@datajos)[1]', 'varchar(20)'), '1900-01-01'),
	   @f_datasus=ISNULL(@parXML.value('(/row/@datasus)[1]', 'varchar(20)'), '2900-01-01')


 select  top 100 
		@tip as tip,
		@tip as subtip,
	   rtrim(a.tip)+' - '+ rtrim(case a.tip when 'G' then 'Depozit'		
											when 'F' then 'Folosinta' end) as tipinv,
       RTRIM(g.Tip_gestiune)+' - '+
       RTRIM(case g.tip_gestiune 
                        when 'M' then 'Materiale' 
                        when 'P' then 'Produse' 
                        when 'C' then 'Cantitativa' 
                        when 'A' then 'Amanuntul' 
                        when 'O' then 'Obiecte'
                        when 'V' then 'Valorica' end)  as tipgest,
       RTRIM(a.Gestiune) as gest,
       RTRIM(g.Denumire_gestiune) as dengest,
       convert(varchar(20),a.data,101) as datainv
 from antetinv a
 --left outer join inventar iv on iv.Gestiunea=a.Gestiune
 left outer join gestiuni g on g.Cod_gestiune=a.Gestiune
 where a.Data between ISNULL(@f_datajos,'') and ISNULL(@f_datasus,'') and
	   isnull(a.Gestiune,'') like '%'+isnull(@f_gestiune,'')+'%' and g.Tip_gestiune='A'
  group by a.Gestiune, g.Denumire_gestiune, a.Data, g.Tip_gestiune,a.tip	
  order by a.Data
 for xml raw
