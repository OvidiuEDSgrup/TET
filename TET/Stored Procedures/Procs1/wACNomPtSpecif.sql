--***
create procedure wACNomPtSpecif @sesiune varchar(50),@parXML XML      
as
declare @searchText varchar(80), @subunitate varchar(9), @tip varchar(2), @gestiune varchar(20),@tert varchar(20), @categoriePret int
declare @aplicatie varchar(100), @subtip varchar(2), @_filtreaza_dupa_nom_specif int, @explicatii varchar(20)
declare @utilizator varchar(10)

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
if @utilizator is null
	return -1

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), '1'), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@aplicatie=ISNULL(@parXML.value('(/row/@aplicatie)[1]', 'varchar(2)'), ''), 
	@gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),
	@explicatii=ISNULL(@parXML.value('(/row/@explicatii)[1]', 'varchar(20)'), ''),
	@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')
if @explicatii <> '' -- valabil pentru BK
	if exists (select 1 from nomspec where tert=@tert) -- daca are nomenclator special va trimite filtrare:
	begin
		set @_filtreaza_dupa_nom_specif=1
		set @parXML.modify ('insert attribute _filtreaza_dupa_nom_specif {sql:variable("@_filtreaza_dupa_nom_specif")} into (/row)[1]')
	end

exec wACNomenclator @sesiune,@parXML
	
