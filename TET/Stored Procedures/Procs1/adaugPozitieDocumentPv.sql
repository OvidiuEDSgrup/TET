-- creaza tabela #bonTemp cu structura corecta
create procedure adaugPozitieDocumentPv @sesiune varchar(50), @xmlDoc xml output, @cod varchar(20)=null, @cantitate decimal(12,3)=1, 
	@discount decimal(5,2)=0, @categoriePret int=1
as
declare @xmlPoz xml, @antetDoc xml, @msgEroare varchar(5000), @nrlinie int, @tip varchar(50)
set nocount on

begin try
	set @tip='21'
	if @xmlDoc.exist('(/date/document/pozitii)[1]')=0
	begin
		set @xmlDoc.modify('insert <pozitii/> as last into (/date/document)[1]')
		set @nrlinie=1
	end
	else
		set @nrlinie=@xmlDoc.value('count(/date/document/pozitii/row)','int')+1

	set @antetDoc = @xmlDoc.query('(/date/document)[1]')
	-- formam un xml trimis de PV la wUnCodNomenclator
	set @antetDoc= replace(replace(convert(varchar(max),@antetdoc),'<document', '<row'),'</document','</row')
	
	if @antetDoc.value('(/row/@cod)[1]','varchar(50)') is null
		set @antetDoc.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
	else
		set @antetDoc.modify('replace value of (/row/@cod)[1] with sql:variable("@cod")')

	if @antetDoc.value('(/row/@cantitate)[1]','varchar(50)') is null
		set @antetDoc.modify ('insert attribute cantitate {sql:variable("@cantitate")} into (/row)[1]')
	else
		set @antetDoc.modify('replace value of (/row/@cantitate)[1] with sql:variable("@cantitate")')

	if @antetDoc.value('(/row/@categoriePret)[1]','varchar(50)') is null
		set @antetDoc.modify ('insert attribute categoriePret {sql:variable("@categoriePret")} into (/row)[1]')
	else
		set @antetDoc.modify('replace value of (/row/@categoriePret)[1] with sql:variable("@categoriePret")')

	set @xmlPoz='<row />'
	exec wUnCodNomenclator @sesiune=@sesiune, @parXML=@antetDoc, @xmlFinal=@xmlPoz output

	declare @pret decimal(12,2), @pretcatalog decimal(12,2), @valoare decimal(12,2), @tva decimal(12,2), @cotaTva decimal(12,2)
	select	@pretcatalog=@xmlPoz.value('(/row/@pretcatalog)[1]', 'decimal(12,2)'), 
			@cotaTva=@xmlPoz.value('(/row/@cotatva)[1]', 'decimal(12,2)')

	set @pret = round(@pretcatalog*(100-@discount)/100,2)
	set @valoare = round(@cantitate*@pret,2)
	set @tva = round(@valoare * @cotaTva / (100 + @cotaTva), 2)

	if @xmlPoz.value('(/row/@pret)[1]','varchar(50)') is null
		set @xmlPoz.modify ('insert attribute pret {sql:variable("@pret")} as last into (/row)[1]')
	else
		set @xmlPoz.modify('replace value of (/row/@pret)[1] with sql:variable("@pret")')
	
	if @xmlPoz.value('(/row/@discount)[1]','varchar(50)') is null
		set @xmlPoz.modify ('insert attribute discount {sql:variable("@discount")} as last into (/row)[1]')
	else
		set @xmlPoz.modify('replace value of (/row/@discount)[1] with sql:variable("@discount")')
	
	if @xmlPoz.value('(/row/@valoare)[1]','varchar(50)') is null
		set @xmlPoz.modify ('insert attribute valoare {sql:variable("@valoare")} as last into (/row)[1]')
	else
		set @xmlPoz.modify('replace value of (/row/@valoare)[1] with sql:variable("@valoare")')
	
	if @xmlPoz.value('(/row/@tva)[1]','varchar(50)') is null
		set @xmlPoz.modify ('insert attribute tva {sql:variable("@tva")} as last into (/row)[1]')
	else
		set @xmlPoz.modify('replace value of (/row/@tva)[1] with sql:variable("@tva")')
	
	if @xmlPoz.value('(/row/@nrlinie)[1]','varchar(50)') is null
		set @xmlPoz.modify ('insert attribute nrlinie {sql:variable("@nrlinie")} as last into (/row)[1]')
	else
		set @xmlPoz.modify('replace value of (/row/@nrlinie)[1] with sql:variable("@nrlinie")')
	
	if @xmlPoz.value('(/row/@tip)[1]','varchar(50)') is null
		set @xmlPoz.modify ('insert attribute tip {sql:variable("@tip")} as last into (/row)[1]')
	else
		set @xmlPoz.modify('replace value of (/row/@tip)[1] with sql:variable("@tip")')
	
	set @xmlDoc.modify('insert sql:variable("@xmlPoz") as last into (/date/document/pozitii)[1]')

end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+' (adaugPozitieDocumentPv)'
	raiserror(@msgeroare,11,1)
end catch
