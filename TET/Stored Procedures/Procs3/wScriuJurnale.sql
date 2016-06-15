
create procedure wScriuJurnale @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @jurnal varchar(20), @o_jurnal varchar(20), @descriere varchar(75), @update bit, @detalii xml

begin try
	select
		@jurnal = @parXML.value('(/row/@jurnal)[1]','varchar(20)'),
		@o_jurnal = @parXML.value('(/row/@o_jurnal)[1]','varchar(20)'),
		@descriere = @parXML.value('(/row/@descriere)[1]','varchar(75)'),
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)

	select
		@detalii = @parXML.query('/row/detalii/row')

	if @detalii.exist('/row') = 0
		set @detalii = null

	if @update=0 and exists(select 1 from jurnale where jurnal=@jurnal)
		raiserror('Acest jurnal exista deja!',16,1)

	if @update=1 and exists(select 1 from jurnale where jurnal=@jurnal) and @jurnal!=@o_jurnal
		raiserror('Acest jurnal exista deja!',16,1)

	if @update=1
		update jurnale set jurnal=@jurnal, descriere=@descriere, detalii=@detalii where jurnal=@o_jurnal
	else
		insert into jurnale
		select rtrim(@jurnal), rtrim(@descriere), '', @detalii

end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
