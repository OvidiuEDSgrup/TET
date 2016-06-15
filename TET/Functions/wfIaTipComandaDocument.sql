
CREATE FUNCTION  wfIaTipComandaDocument(@tip_document varchar(200))
RETURNS varchar(10)
AS
begin
	RETURN (case @tip_document when 'RM' then 'CA' when 'AP' then 'CL' end)
end
