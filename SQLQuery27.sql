select * from bonuri b
	left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
	where b.Numar_bon=2 and b.Data='04/30/2012'