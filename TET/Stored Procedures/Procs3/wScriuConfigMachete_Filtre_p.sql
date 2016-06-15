--***
create procedure wScriuConfigMachete_Filtre_p (@sesiune varchar(50), @parXML xml)
as

declare @meniu varchar(20), @tip varchar(2), @nivel int, @populare xml
		,@p_meniu varchar(20), @update bit

set @meniu=rtrim(isnull(@parXML.value('(/row/@meniu)[1]','varchar(20)'),''))
set @tip=rtrim(isnull(@parXML.value('(/row/@tip_m)[1]','varchar(2)'),''))
set @nivel=isnull(@parXML.value('(/row/@nivel)[1]','int'),0)

set @p_meniu=rtrim(isnull(@parXML.value('(/row/@p_meniu)[1]','varchar(20)'),''))
set @update=rtrim(isnull(@parXML.value('(/row/@update)[1]','bit'),'0'))

if @update=0 and @p_meniu='' and (@nivel<>1)
begin
	set @populare = (select @populare for xml raw)
	if @meniu<>''
		set @populare.modify('insert(attribute t_meniu {sql:variable("@meniu")}) into (/row[1])')
	if @tip<>''
		set @populare.modify('insert(attribute t_tip {sql:variable("@tip")}) into (/row[1])')
	select @populare
end
