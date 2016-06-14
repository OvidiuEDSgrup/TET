--drop proc rapContrBeneficiari 
alter procedure yso.rapContrBeneficiari @tipContract char(2)=null as 
select p.*,t.Denumire as den_tert,isnull(n.Denumire,g.Denumire) as den_cod,x.Pret as disc_doi,x.Cantitate as disc_trei 
from pozcon p 
inner join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Data=p.Data and c.Tert=p.Tert
inner join terti t on t.Subunitate=c.Subunitate and t.Tert=c.Tert
left join nomencl n on n.Cod=p.Cod and p.Mod_de_plata=''
left join grupe g on g.Grupa=p.Cod and p.Mod_de_plata='G'
left join pozcon x on x.Subunitate='EXPAND' and x.Tip=p.Tip and x.Contract=p.Contract and x.Data=p.Data and x.Tert=p.Tert 
	and x.Cod=p.Cod and x.Numar_pozitie=p.Numar_pozitie
left join pozcon x2 on x2.Subunitate='EXPAND2' and x2.Tip=p.Tip and x2.Contract=p.Contract and x2.Data=p.Data and x2.Tert=p.Tert 
	and x2.Cod=p.Cod and x2.Numar_pozitie=p.Numar_pozitie
WHERE p.subunitate='1' and (ISNULL(@tipContract,'')='' or p.Tip=rtrim(@tipContract))
order by p.Tert,p.Contract,p.Cod