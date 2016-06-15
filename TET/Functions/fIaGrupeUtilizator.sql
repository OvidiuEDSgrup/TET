--***
create function fIaGrupeUtilizator(@utilizator varchar(50))
returns @grupe table(grupa varchar(50))
as
begin
	/*
	;with x(utilizator,grupa)
	as
	(	--select u.ID utilizator, gr.grupa as grupa from utilizatori u inner join grupeUtilizatoriRia gr on u.ID=gr.utilizator where u.ID=@utilizator union all
		select '' utilizator, @utilizator union all
		select u.utilizator utilizator, gr.grupa as grupa from x u inner join grupeUtilizatoriRia gr on u.grupa=gr.utilizator
	)
	*/
	
	--> chestia comentata de mai sus crapa daca cineva undeva nu are grija la definirea grupelor si genereaza ceva bucla;
	-->		asa ca e mai sigur while-ul de mai jos (oricat de urat ar fi ca aspect)
	insert into @grupe(grupa)
	select @utilizator
	
	declare @numarGrupe int, @numarGrupeAnterior int
	select @numarGrupe=1, @numarGrupeAnterior=0
	while (@numarGrupe<>@numarGrupeAnterior)
	begin
		select @numarGrupeAnterior=@numarGrupe
		insert into @grupe(grupa)
		select gr.grupa from @grupe g inner join grupeUtilizatoriRia gr on g.grupa=gr.utilizator
			where not exists (select 1 from @grupe g1 where g1.grupa=gr.grupa)
		select @numarGrupe=(select count(1) from @grupe)
	end
	return
end
