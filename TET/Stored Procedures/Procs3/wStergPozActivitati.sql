--***
create procedure wStergPozActivitati @sesiune varchar(50), @parXML xml  
as  
  
Declare @eroare xml , @tip char(2), @fisa varchar(20), @data datetime, @numar_pozitie int, @idPozActivitati int

--begin tran
begin try

select	@tip = isnull(@parXML.value('(/row/@tip)[1]', 'char(2)'),0),
		@fisa = isnull(@parXML.value('(/row/@fisa)[1]', 'varchar(20)'),0),
		@data = isnull(@parXML.value('(/row/@data)[1]', 'datetime'),0),
		@numar_pozitie = isnull(@parXML.value('(/row/@numar_pozitie)[1]', 'int'),0),
		@idPozActivitati = @parXML.value('(/row/@idPozActivitati)[1]', 'int')

if (@idPozActivitati is not null)
	select @tip=pa.Tip, @fisa=pa.Fisa, @data=pa.Data, @numar_pozitie=pa.Numar_pozitie
	from pozactivitati pa where pa.idPozActivitati=@idPozActivitati

if (@idPozActivitati is null)
	select @idPozActivitati=pa.idPozActivitati
	from pozactivitati pa where @tip=pa.Tip and @fisa=pa.Fisa and @data=pa.Data and @numar_pozitie=pa.Numar_pozitie

if not exists ( select 1 from pozactivitati where idPozActivitati=@idPozActivitati)
	raiserror('Nu am gasit pozitia in baza de date!',11,1)
-->	acesti parametri se folosesc la calculul elementelor KMBORD si OREBORD pentru date care urmeaza cronologic datelor sterse:
	declare @tipActivitate varchar(1), @element varchar(20), @data_plecarii datetime,
			@ora_plecarii varchar(6), @masina varchar(20),
			@bordVechi decimal(15,2), @bordNou decimal(15,2), @bordDif decimal(15,2)
			
	select @data_plecarii=pa.data_plecarii, @ora_plecarii=pa.ora_plecarii, @masina=a.masina
	from pozactivitati pa
		inner join activitati a on pa.idactivitati=a.idactivitati
	where pa.idPozActivitati=@idPozActivitati
	
	select @tipActivitate=(
		select t.Tip_activitate from tipmasini t inner join grupemasini g on g.tip_masina=t.Cod
			inner join masini m on m.grupa=g.Grupa
		where cod_masina=@masina
		)
	select @element=(case when @tipActivitate='L' then 'OREBORD' else 'Kmbord' end)
	
	exec iaValoareElementMM @element=@element, @masina=@masina, @data=@data,
			@data_plecarii=@data_plecarii, @ora_plecarii=@ora_plecarii, @valoare=@bordVechi output
	
	delete from elemactivitati 
		where idPozActivitati=@idPozActivitati
	delete from pozactivitati 
		where idPozActivitati=@idPozActivitati
	
	exec iaValoareElementMM @element=@element, @masina=@masina, @data=@data,
			@data_plecarii=@data_plecarii, @ora_plecarii=@ora_plecarii, @valoare=@bordNou output
	
	select @bordDif=@bordNou-@bordVechi
	exec updateElementeAnterioareMM @bordDif=@bordDif, @element=@element,
		@masina=@masina, @data=@data, @data_plecarii=@data_plecarii,
		@ora_plecarii=@ora_plecarii

	exec wIaPozActivitati @sesiune=@sesiune, @parXML=@parXML

--commit tran
end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj = ERROR_MESSAGE() + '(wStergPozActivitati '+convert(varchar(20), ERROR_LINE())+')'
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	raiserror(@mesaj, 11, 1)
end catch
