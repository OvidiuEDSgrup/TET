
CREATE procedure wmAlegCodDocumente @sesiune varchar(50), @parXML xml
as

if exists(select * from sysobjects where name='wmAlegCodDocumenteSP' and type='P')
begin
	exec wmAlegCodDocumenteSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end

	declare 
		@utilizator varchar(50), @proc_detalii varchar(100), @meniu_detalii varchar(100)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	if @utilizator is null 
		return -1
	set @proc_detalii=@parXML.value('(/*/@proc_detalii_next)[1]','varchar(100)')
	set @meniu_detalii=@parXML.value('(/*/@meniu_detalii_next)[1]','varchar(100)')

	if @parXML.exist('(/row/@wmNomenclator.procdetalii)[1]')=1
		set @parXML.modify('replace value of (/row/@wmNomenclator.procdetalii)[1] with sql:variable("@proc_detalii")')                     
	else           
		set @parXML.modify ('insert attribute wmNomenclator.procdetalii {sql:variable("@proc_detalii")} into (/row)[1]') 
	
	if @parXML.exist('(/row/@wmNomenclator.meniuDetalii)[1]')=1
		set @parXML.modify('replace value of (/row/@wmNomenclator.meniuDetalii)[1] with sql:variable("@meniu_detalii")')                     
	else           
		set @parXML.modify ('insert attribute wmNomenclator.meniuDetalii {sql:variable("@meniu_detalii")} into (/row)[1]')

	exec wmNomenclator @sesiune=@sesiune,@parXML=@parXML
