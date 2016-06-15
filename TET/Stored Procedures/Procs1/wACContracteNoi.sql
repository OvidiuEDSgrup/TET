
CREATE PROCEDURE wACContracteNoi @sesiune VARCHAR(50), @parXML XML
AS
set transaction isolation level read uncommitted

DECLARE @tert VARCHAR(50), @searchText VARCHAR(200), @tip varchar(50)
	--> deoarece @tip e cam generic adaug alte sanse de a filtra pe tip in wACContracteNoi
	-->		@tip de asemenea e intotdeauna completat - venind din configurari, si de obicei nu e controlabil
	,@tip_contracte_beneficiari bit, @tip_contracte_furnizori bit, @tip_contracte_livrare bit, @tip_contracte_aprovizionare bit, @tipuriContracte varchar(100)

SET @searchText = '%'+replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(80)'), ''), ' ', '%')+'%'
SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(50)'),'')
SET @tip = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(50)'),'')
SET @tip_contracte_beneficiari = isnull(@parXML.value('(/*/@tip_contracte_beneficiari)[1]', 'bit'),0)
SET @tip_contracte_furnizori = isnull(@parXML.value('(/*/@tip_contracte_furnizori)[1]', 'bit'),0)
SET @tip_contracte_livrare = isnull(@parXML.value('(/*/@tip_contracte_livrare)[1]', 'bit'),0)
SET @tip_contracte_aprovizionare = isnull(@parXML.value('(/*/@tip_contracte_aprovizionare)[1]', 'bit'),0)

if @tip_contracte_beneficiari=1 or @tip_contracte_furnizori=1 or @tip_contracte_livrare=1 or @tip_contracte_aprovizionare=1
begin
	set @tip=''
	select @tipuriContracte=','
		+(case when @tip_contracte_beneficiari=1 then 'CB,' else '' end)
		+(case when @tip_contracte_furnizori=1 then 'CF,' else '' end)
		+(case when @tip_contracte_livrare=1 then 'CL,' else '' end)
		+(case when @tip_contracte_aprovizionare=1 then 'CA,' else '' end)
end

SELECT TOP 100
	ct.idContract AS cod, 
	RTRIM(ct.numar) + '/' + replace(CONVERT(VARCHAR(10), ct.data, 103),'/','-')+'('+rtrim(isnull(t.denumire,''))+')' AS denumire, 
	'Tip "'+ct.tip+'" Gest. ' + RTRIM(g.Denumire_gestiune) AS info
FROM Contracte ct
left JOIN gestiuni g ON g.Cod_gestiune = ct.gestiune and g.Subunitate='1'
left JOIN terti t ON t.tert = ct.tert and t.Subunitate='1'
where (ct.numar LIKE @searchText OR ct.explicatii LIKE @searchText or t.Denumire like @searchText)
	AND (@tip='' OR ct.tip = @tip)
	and (@tipuriContracte is null or charindex(','+rtrim(ct.tip)+',',@tipuriContracte)>0)
	AND (@tert='' OR ct.tert = @tert)
FOR XML raw, root('Date')
