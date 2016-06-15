--***
create procedure copiereUtilizatorED(@utilizator varchar(10), @utilizator_model varchar(10), @meniuri int, @rapoarte int, @proprietati int, @stergere int, @grupe int = 1)
as
begin
	--Aici se copiaza meniurile atribuite unui Utilizator pentru alt utilizator
	if (@meniuri=1)
	begin
		if (@stergere=1)
			delete w1 from webConfigMeniuUtiliz w1 where w1.IdUtilizator=@utilizator
		insert into webConfigMeniuUtiliz(IdUtilizator, IdMeniu, Drepturi, meniu)
		select @utilizator,IdMeniu,drepturi, meniu
		from webConfigMeniuUtiliz w
		WHERE IdUtilizator=@utilizator_model
			and not exists (select 1 from webConfigMeniuUtiliz w1 where w1.IdUtilizator=@utilizator and w1.IdMeniu=w.IdMeniu)
	end

	--Aici se copiaza rapoartele atribuite unui Utilizator Utilizator pentru alt utilizator
	if(@rapoarte=1)
	begin
		if (@stergere=1)
				delete w1 from webConfigRapoarte w1 where w1.utilizator=@utilizator
		insert into webConfigRapoarte(utilizator, caleRaport)
		select @utilizator,caleRaport
		from webConfigRapoarte w
		WHERE utilizator=@utilizator_model 
			and not exists (select 1 from webConfigRapoarte w1 where w1.utilizator=@utilizator and w1.caleRaport=w.caleRaport)
	end

	--Aici se copiaza propietatile atribuite unui Utilizator pentru alt utilizator
	if(@proprietati=1)
	begin
		if (@stergere=1)
				delete w1 from proprietati w1 where w1.cod=@utilizator and w1.tip='UTILIZATOR'
		insert into proprietati(tip, cod, cod_proprietate, valoare, valoare_tupla)
		select tip,@utilizator,cod_proprietate,valoare,valoare_tupla
		from proprietati w
		WHERE cod=@utilizator_model and tip='UTILIZATOR'
			and not exists (select 1 from proprietati w1 where w1.tip='UTILIZATOR' and w1.Cod=@utilizator and
						w1.Cod_proprietate=w.Cod_proprietate and w1.Valoare=w.Valoare and w1.Valoare_tupla=w.Valoare_tupla)
	end

	-- se copiaza grupele asociate utilizatorului:	
	if(@grupe=1)
	begin
		if (@stergere=1)
				delete w1 from grupeUtilizatoriRia w1 where w1.utilizator=@utilizator
		insert into grupeUtilizatoriRia(utilizator, grupa)
		select @utilizator, w.grupa
		from grupeUtilizatoriRia w
		WHERE w.utilizator=@utilizator_model
	end
end
