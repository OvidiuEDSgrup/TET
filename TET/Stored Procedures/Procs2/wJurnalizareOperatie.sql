
--***
CREATE PROCEDURE wJurnalizareOperatie @sesiune VARCHAR(50), @parXML XML, @obiectSql VARCHAR(100)
AS
BEGIN
	DECLARE 
		@utilizator VARCHAR(100), @tip varchar(2)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
    set @parXML=convert(xml,replace(replace(convert(varchar(max),@parXML), '</parametri', '</row'), '<parametri', '<row'))
    
	set @tip=@parXML.value('(/*/@tip)[1]','varchar(2)')

	INSERT INTO webJurnalOperatii (sesiune, utilizator, data, tip, obiectSql, parametruXML)
	VALUES (@sesiune, @utilizator, GETDATE(), @tip, @obiectSql,@parXML)
END
