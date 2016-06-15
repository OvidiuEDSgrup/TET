
create procedure wACNomenclTehnologie @sesiune varchar(50),@parXML XML      
as
	declare
		@tip_tehnologie varchar(20)

	select
		@tip_tehnologie=ISNULL(@parXML.value('(/row/@tip_tehn)[1]', 'varchar(20)'), 'P')

	/* Doar la produse si servicii putem sugera un cod de articol din nomenclator*/
	IF @tip_tehnologie NOT IN ('S','P')
		return

	set @parXML.modify('insert attribute tipNomencl {sql:variable("@tip_tehnologie")} into (/row[1])')
	exec wACNomenclator @sesiune=@sesiune, @parXML=@parXML
