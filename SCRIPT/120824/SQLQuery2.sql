select c.Descriere,bp.*,a.* from bp inner join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
inner join comenzi c on c.Comanda=bp.Client
where bp.Cantitate<0 and a.Contract is not null
order by a.Data_bon desc