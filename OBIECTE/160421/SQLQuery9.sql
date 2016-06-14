select p.Numar,p.Data,p.Tip,* from LegaturiStornare l join pozdoc p on p.idPozDoc=l.idSursa
order by l.idStorno desc