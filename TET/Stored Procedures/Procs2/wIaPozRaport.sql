--***
CREATE procedure  [dbo].[wIaPozRaport]  @sesiune varchar(50), @parXML xml
as
declare @angajat varchar(30),@luna_lit varchar(300), @usr varchar(10),
		@ore_realizate varchar(8), @luna_cif varchar(50), @year varchar(4)


select 
	 @angajat = rtrim(isnull(@parXML.value('(/row/@angajat)[1]', 'varchar(30)'), '')),
	 @luna_lit = rtrim(isnull(@parXML.value('(/row/@luna)[1]', 'varchar(30)'), ''))


select @luna_cif= (case when @luna_lit like 'Ianuarie%' then '1' when  @luna_lit like 'Februarie%' then '2' when @luna_lit like 'Martie%' then '3'
				    when @luna_lit like 'Aprilie%' then '4' when @luna_lit like 'Mai%' then '5' when @luna_lit like 'Iunie%' then '6'
				     when @luna_lit like 'Iulie%' then '7' when @luna_lit like 'August%' then '8' when @luna_lit like 'Septembrie%' then '9'
				      when @luna_lit like 'Octombrie%' then '10' when @luna_lit like 'Noiembrie%' then '11' when @luna_lit like 'Decembrie%' then '12' end)
				      	 
set @year = RIGHT(@luna_lit,4)

select top 100
i.Descriere as angajat,convert(char(10),r.Data_start,101 ) as data_i,convert(char(10),r.Data_stop,101 ) as data_s,
r.Activitati as activitati, SUBSTRING(r.ore_lucrate,1,2)+':'+SUBSTRING(r.ore_lucrate,3,2) as ore,
isnull(t.Denumire,'<intern>') as client, r.IDOrdin as sarcina

from Raport_activitate r
left join infotert i on i.Identificator=r.ID_angajat 
left join Sarcini s on s.IDSarcina = r.IDOrdin
left join sesizari z on z.Cod = s.IDSesizare
left join terti t on t.Tert = z.Client

where
i.Descriere like '%'+@angajat+'%'
and MONTH(r.Data_start) = @luna_cif and MONTH(r.Data_stop) = @luna_cif
and YEAR(r.data_start )= @year

for xml raw
