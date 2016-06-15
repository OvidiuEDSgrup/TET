--***
CREATE FUNCTION dbo.fn_LMFiltrate (@user varchar(50))
RETURNS TABLE
AS
RETURN 
(
    select distinct lm.cod 
	from proprietati p 
	inner join lm on lm.cod like rtrim(p.valoare) + '%'
	where p.tip='UTILIZATOR' and p.cod=@user and p.cod_proprietate='LOCMUNCA');
