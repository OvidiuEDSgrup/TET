create procedure wPopTabDecontariAux @sesiune varchar(50), @parXML xml
as
begin
	declare @comanda varchar(50),@lm varchar(20), @data_lunii datetime

	set @comanda = @parXML.value('/row[1]/@comanda','varchar(20)')
	set @lm = @parXML.value('/row[1]/@lm','varchar(20)')
	set @data_lunii = @parXML.value('/row[1]/@data','datetime')

	select @comanda comanda_furnizor, @lm l_m_furnizor, convert(char(10),@data_lunii,101) as data_lunii for xml raw
end
