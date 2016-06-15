
create procedure wIaArticoleCost @sesiune varchar(50), @parXML xml 
as  
declare @art varchar(10) , @f_denumire varchar(50), @f_artcost varchar(10), @utilizator varchar(20), @f_baza_rg varchar(10), @f_baza_rl varchar(10)
    
select @f_denumire=isnull(@parXML.value('(/row/@f_denumire)[1]','varchar(80)'),''),
	@f_artcost=isnull(@parXML.value('(/row/@f_artcost)[1]','varchar(10)'),''),
	@f_baza_rg=isnull(@parXML.value('(/row/@f_baza_rg)[1]','varchar(10)'),''),
	@f_baza_rl=isnull(@parXML.value('(/row/@f_baza_rl)[1]','varchar(10)'),'')
     
select rtrim(a.articol_de_calculatie) as art_cost, a.Ordinea_in_raport ordinea_in_raport, rtrim(a.Denumire) as denumire,
	a.Grup as grup, a.baza_pt_regia_sectiei as baza_rl, a.Baza_pt_regia_generala baza_rg, a.Baza_pt_ch_aprovizionare as baza_ch_ap,
	a.Baza_pt_ch_desfacere as baza_ch_des
from artcalc a
where (isnull(@f_denumire,'')='' or a.Denumire like '%'+@f_denumire+'%')
	and (isnull(@f_artcost,'')='' or a.articol_de_calculatie like @f_artcost+'%')
	and (isnull(@f_baza_rg,'')='' or (a.Baza_pt_regia_generala=1 and @f_baza_rg='DA') or (a.Baza_pt_regia_generala=0 and @f_baza_rg='NU'))
	and (isnull(@f_baza_rl,'')='' or (a.baza_pt_regia_sectiei=1 and @f_baza_rl='DA') or (a.baza_pt_regia_sectiei=0 and @f_baza_rl='NU'))
order by articol_de_calculatie
for xml raw

/*
select * from artcalc
*/		 
		 
