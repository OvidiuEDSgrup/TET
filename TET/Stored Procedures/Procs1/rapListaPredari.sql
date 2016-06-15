
create procedure rapListaPredari @datajos datetime=null, @datasus datetime=null, 
								 @gestiune varchar(9)=null, @cod_produs varchar(20)=null

as
begin
	
	if @datajos is null
		set @datajos = dateadd(yy,-50,getdate())

	if @datasus is null
		set @datasus = dateadd(yy,50,getdate())

	select	rtrim(p.Numar) as Numar
			,p.Data as Data
			,rtrim(p.Cod)  as Cod
			,rtrim(n.Denumire) as Denumire
			,rtrim(n.UM) as UM
			,rtrim(p.Cod_intrare) as CodIntrare
			,p.Cantitate as Cantitate
			,p.Pret_de_stoc as PretStoc
	from pozdoc p
	inner join nomencl n on n.cod=p.cod
	where p.tip = 'PP'
			and (p.Data between @datajos and @datasus)
			and (@gestiune is null or @gestiune='' or p.Gestiune = @gestiune)
			and (@cod_produs is null or @cod_produs='' or p.Cod = @cod_produs)
	order by p.Data, p.cod
end
