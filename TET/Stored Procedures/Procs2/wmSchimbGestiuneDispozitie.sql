
create procedure wmSchimbGestiuneDispozitie @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmSchimbGestiuneDispozitieSP' and type='P')
begin
	exec wmSchimbGestiuneDispozitieSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @gestiune varchar(13), @idDisp int, @numeAtr varchar(50), @gestprim varchar(50)
select	@idDisp = @parXML.value('(/row/@iddisp)[1]', 'int'),
		@gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(13)'),
		@gestprim = @parXML.value('(/row/@gestprim)[1]', 'varchar(13)'),
		-- folosesc acest atribut pt. a avea aceasi procedura la modificare 
		@numeAtr = isnull(@parXML.value('(/row/@wmSchimbGestiuneDispozitie.numeAtr)[1]', 'varchar(50)'),'@gestiune')

if @numeAtr not in ('@gestiune', '@gestprim')
	raiserror('Atributul XML trimis nu este tratat in aceasta procedura.',16 ,1)

-- procedura e apelata prima data cu gestiune = '' pt. afisare lista gestiuni, iar apoi re-apelata cu @gestiune aleasa
if isnull(@gestiune,'') = '' and @numeAtr = '@gestiune'
	or isnull(@gestprim,'') = '' and @numeAtr = '@gestprim'
begin
	set @parXML.modify ('insert attribute wmIaGestiuni.procdetalii {"wmSchimbGestiuneDispozitie"} into (/row)[1]')
	set @parXML.modify ('insert attribute wmIaGestiuni.titlumacheta {"Schimbare gestiune"} into (/row)[1]')
	set @parXML.modify ('insert attribute wmIaGestiuni.numeatr {sql:variable("@numeAtr")} into (/row)[1]')
	
	exec wmIaGestiuni @sesiune=@sesiune, @parXML=@parXML
	return 0
end

if @numeAtr = '@gestiune'
	-- in conditiile curente, nu se insereaza antet fara @gestiune completata
	update AntDisp
		set detalii.modify('replace value of (/row/@gestiune)[1] with sql:variable("@gestiune")') 
	where idDisp = @idDisp

if @numeAtr = '@gestprim'
	-- in conditiile curente, nu se insereaza antet fara @gestiune completata
	update AntDisp
		set detalii.modify('replace value of (/row/@gestprim)[1] with sql:variable("@gestprim")') 
	where idDisp = @idDisp

SELECT 'back(2)' AS actiune
FOR XML RAW,ROOT('Mesaje')
