--***
create procedure wACNomSpecif @sesiune varchar(50),@parXML XML      
as
set transaction isolation level read uncommitted
if exists(select * from sysobjects where name='wACNomSpecifSP' and type='P')      
begin
	exec wACNomSpecifSP @sesiune,@parXML
	return 0
end
declare @searchText varchar(80), @subunitate varchar(9), @tip varchar(2), @gestiune varchar(20),@tert varchar(20), @categoriePret int
declare @aplicatie varchar(100), @subtip varchar(2)
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
	@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')
	
    
IF @aplicatie <> ''
	SET @tip = @aplicatie
SET @searchText = REPLACE(@searchText, ' ', '%')

-- folosim tabela temporara pentru a face join pe tabelele de preturi doar cu liniile filtrate.
SELECT TOP 100 rtrim(n.Cod_special) AS cod, rtrim(nomencl.Denumire) AS info, rtrim(n.denumire) AS denumire
FROM nomspec n
INNER JOIN nomencl
	ON nomencl.Cod = n.Cod
WHERE (
		n.denumire LIKE '%' + @searchText + '%'
		OR n.cod_special LIKE @searchText + '%'
		)
	AND n.tert = @Tert
ORDER BY patindex('%' + @searchText + '%', n.denumire), 1
FOR XML raw

