--***
/* returneaza lista de gestiuni din care poate vinde in PVria. Lista include si gestiunea cu amanuntul. */
CREATE FUNCTION wfListaGestiuniAtasatePV (@gestutiliz varchar(50))
RETURNS VarChar(250)
AS
BEGIN
return rtrim(@gestutiliz)+';'+isnull(rtrim((select val_alfanumerica from par where tip_parametru='PG' and parametru=@gestutiliz))+';','')
END

