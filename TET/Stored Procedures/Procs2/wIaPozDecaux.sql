--***
create procedure  [wIaPozDecaux] @sesiune varchar(50), @parXML xml  
as     
declare @subunitate varchar(9), @l_m_furnizor varchar(9), @tip varchar(2), @data_lunii datetime, @comanda_furnizor varchar(20) 
  
select @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
	@data_lunii=ISNULL(@parXML.value('(/row/@data_lunii)[1]', 'datetime'), '01/01/1901'),  
	@l_m_furnizor=ISNULL(@parXML.value('(/row/@l_m_furnizor)[1]', 'varchar(9)'), ''),
	@comanda_furnizor=ISNULL(@parXML.value('(/row/@comanda_furnizor)[1]', 'varchar(20)'), '') 

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select 
	rtrim(p.subunitate) as subunitate, 
	@tip as subtip, 
	convert(char(10),p.data,101) as data, 
	rtrim(p.L_m_furnizor) as l_m_furnizor,  
	rtrim(lmf.denumire) as denl_m_furnizor,
	rtrim(p.Comanda_furnizor) as comanda_furnizor, 
	rtrim(cf.descriere) as dencomanda_furnizor,
	rtrim(p.Numar_document) as numar_document,   
	rtrim(p.Loc_de_munca_beneficiar) as loc_de_munca_beneficiar, 
	rtrim(lmb.denumire) as denloc_de_munca_beneficiar, 
	rtrim(p.Comanda_beneficiar) as comanda_beneficiar,
	rtrim(cb.descriere) as dencomanda_beneficiar,
	rtrim(p.articol_de_calculatie_benef) as articol_de_calculatie_benef,
	rtrim(ac.Denumire) as denarticol_benef,
	convert(decimal(12, 3), p.cantitate) as cantitate,
	convert(decimal(20, 3), p.cantitate*isnull(pr.pret_unitar,0)) as valoare_calculata,
	convert(decimal(20, 3), isnull(pr.pret_unitar,0)) as pret_unitar_calculat
	--, (case when p.automat=1 and exists (select 1 from decaux where subunitate=@subunitate and data=@data and L_m_furnizor=@l_m_furnizor and Comanda_furnizor=@comanda_furnizor and automat=0) then '#808080' else '#000000' end)  as culoare 
from decaux p 
	left outer join lm lmf on lmf.cod = p.L_m_furnizor 
	left outer join comenzi cf on cf.subunitate = p.subunitate and cf.comanda = p.Comanda_furnizor
	left outer join lm lmb on lmb.cod = p.Loc_de_munca_beneficiar 
	left outer join comenzi cb on cb.subunitate = p.subunitate and cb.comanda = p.Comanda_beneficiar
	left outer join artcalc ac on ac.Articol_de_calculatie = p.Articol_de_calculatie_benef  
	outer apply(select top 1 pret_unitar from pretun pr where pr.comanda=p.Comanda_furnizor and dbo.eom(pr.data_lunii)=dbo.eom(p.data))pr
where p.subunitate=@subunitate 
	and dbo.eom(p.data)=@data_lunii and p.L_m_furnizor=@l_m_furnizor and p.Comanda_furnizor=@comanda_furnizor  
order by data,l_m_furnizor,comanda_furnizor  
for xml raw
