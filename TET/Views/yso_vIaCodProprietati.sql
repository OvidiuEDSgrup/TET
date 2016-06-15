create view yso_vIaCodProprietati as
select distinct 
       rtrim(p.Cod) as cod,
       RTRIM(n.Denumire) as denumire_cod,
       rtrim(p.Cod_proprietate) as codprop,
	   RTRIM(cp.descriere) as descriere,
	   RTRIM(p.Valoare) as valoare
	   from proprietati p
		inner join catproprietati cp on cp.Cod_proprietate=p.Cod_proprietate 
		inner join tipproprietati tp on tp.Cod_proprietate=p.Cod_proprietate and tp.Tip='NOMENCL' 
		left join nomencl n on n.Cod=p.Cod
