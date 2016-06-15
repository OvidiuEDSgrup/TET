
create procedure wmSchimbTertDispozitie @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmSchimbTertDispozitieSP' and type='P')
begin
	exec wmSchimbTertDispozitieSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @tert varchar(13) , @idDisp int
select	@tert = @parXML.value('(/row/@tert)[1]', 'varchar(13)'),
		@idDisp = @parXML.value('(/row/@iddisp)[1]', 'int')

if isnull(@tert,'')=''
begin
	set @parXML.modify ('insert attribute wmIaTerti.procdetalii {"wmSchimbTertDispozitie"} into (/row)[1]')
	--if @parXML.exist('(/*/@faradetalii)')=0
	--		set @parXML.modify ('insert attribute faradetalii {"1"} into (/row)[1]')
	
	exec wmIaTerti @sesiune=@sesiune, @parXML=@parXML
	return 0
end

-- in conditiile curente, nu se insereaza antet fara @tert completat
update AntDisp
	set detalii.modify('replace value of (/row/@tert)[1] with sql:variable("@tert")') 
where idDisp = @idDisp

SELECT 'back(2)' AS actiune
FOR XML RAW,ROOT('Mesaje')
