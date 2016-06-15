--***
CREATE proc [dbo].[apelCantarV1] @sesiune varchar(50), @parxml xml
as
begin
   select str(n.cod,0),str(n.cod,0),str(1,0),str(p.Pret_cu_amanuntul,0,2),str(0,0),str(0,0),1,str(0,0),str(0,0),str(0,0),0,0,0,rtrim(n.denumire)+','
   from ghita..nomencl n
   inner join  
   		(select RANK() over (partition by p.cod_produs order by p.tip_pret desc,p.data_inferioara desc) as nrank, p.Cod_produs,p.Pret_cu_amanuntul
			from preturi p
			inner join nomencl n on p.Cod_produs=n.Cod
			where p.um='1' 
			and ((p.tip_pret=1 and GETDATE()>=p.Data_inferioara)
				or (p.tip_pret=2 and GETDATE() between p.Data_inferioara and p.data_superioara))) p 
  
   on n.Cod=p.Cod_produs and p.nrank=1
   where UM='kg'
end

