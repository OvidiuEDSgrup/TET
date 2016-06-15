CREATE VIEW yso_vIaGrupe AS
select rtrim(g.Tip_de_nomenclator) as tip
	,rtrim(g.Tip_de_nomenclator)+'-' + 
		case g.Tip_de_nomenclator
		when 'A' then 'Marfa'
		when 'F' then 'Mijloace fixe'
		when 'M' then 'Material'
		when 'O' then 'Obiecte de inventar'
		when 'P' then 'Produs'
		when 'R' then 'Servicii furnizate'
		when 'S' then 'Servicii prestate'
		end
	as denTip
	, rtrim(g.grupa) as grupa,rtrim(g.Denumire) as denumire, rtrim (isnull(p.Cod_proprietate,'')) as cont  
	from grupe g 
		left join propgr p on g.grupa=p.Grupa
