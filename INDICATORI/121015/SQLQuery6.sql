--insert tet..indicatori
select * from indicatori i where i.Cod_Indicator not in (select Cod_Indicator from tet..indicatori)

--insert tet..compcategorii
select * from compcategorii c where not exists (select 1 from tet..compcategorii t where t.Cod_Categ=c.Cod_Categ
and t.Rand=c.Rand)

--insert tet..colind
select *,0 from colind c where not exists (select 1 from tet..colind t where t.Cod_indicator=c.Cod_indicator
and t.Numar=c.Numar)

 --insert tet..categorii
select * from categorii c where c.Cod_categ not in (select Cod_categ from tet..categorii)

select * from colind