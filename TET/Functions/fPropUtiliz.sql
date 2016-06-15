--***
create function fPropUtiliz(@sesiune varchar(20)=null)
returns table 
as
return(
	select lm.cod as valoare, p.cod_proprietate
	from proprietati p left join lm on lm.cod like rtrim(p.valoare)+'%'
		where p.tip='UTILIZATOR' and p.cod_proprietate='LOCMUNCA' and p.cod=dbo.fIaUtilizator(@sesiune) 
			and p.cod<>'' and p.valoare<>'' group by lm.Cod, p.Cod_proprietate
	union all
	select p.valoare, p.cod_proprietate
	from proprietati p
		where p.tip='UTILIZATOR' and p.cod_proprietate<>'LOCMUNCA' and p.cod=dbo.fIaUtilizator(@sesiune)
			and p.cod<>'' and p.valoare<>''
	)
