--***
create function [dbo].[wfValidareCheltuieli] (@document xml) returns xml
as begin
	declare @eroare xml
	set @eroare='<error coderoare="0" msgeroare=""/>'
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@tipDoc)[1]', 'char(2)'), '') not in ('RS', 'CM', 'AI','PI','NC','FF') 
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Documentul nu se poate modifica!"')
		return @eroare
	end
	declare @aiPC int, @liPC int, @dd datetime
	set @liPC=ISNULL((select val_numerica from par where Tip_parametru='PC' and Parametru='LUNAINC' AND Val_logica=1),0)
	set @aiPC=ISNULL((select val_numerica from par where Tip_parametru='PC' and Parametru='ANULINC' AND Val_logica=1),0)
	set @dd=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), '1921-01-01')
	if @aiPC>YEAR(@dd) or (@aiPC=YEAR(@dd) and @liPC>=MONTH(@dd))
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "2"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Luna inchisa din punct de vedere al costurilor!"')
		return @eroare
	end
	return @eroare
end
