--***
create procedure [dbo].[rapEticheteNomenclator] @sesiune varchar(50),@parXML xml
as
begin
	set transaction isolation level read uncommitted
	declare @utilizator varchar(100)

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select 
		row_number() over (order by t.cod) as numar,
		t.cod as cod,
		isnull(cbb.cod_de_bare,'') as cod_bare,
		t.pret as pret_cu_amanuntul,
		t.pretvechi,
		rtrim(n.denumire) as denumire,
		rtrim(n.um) as um
	from temp_ListareCodBare t
	inner join nomencl n on t.cod=n.cod
	outer apply (select top 1 cb.Cod_produs,cb.cod_de_bare from codbare cb where cb.Cod_produs=t.cod and cb.cod_de_bare<>'') cbb
	where utilizator=@utilizator
end
