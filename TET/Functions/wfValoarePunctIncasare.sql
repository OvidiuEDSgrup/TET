--***
/* returneaza lista de gestiuni din care poate vinde in PVria. Lista include si gestiunea cu amanuntul. */
CREATE FUNCTION wfValoarePunctIncasare (@bon xml)
RETURNS decimal(15,5)
AS
begin
return
	@bon.value('(/date/document/fidelizare/@valoarePunctIncasare)[1]','decimal(15,5)')
end
