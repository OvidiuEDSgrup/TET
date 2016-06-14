/*
with cl as
(select c.tip,c.numar,c.tert,c.data,pc.cod,pc.cantitate,pc.pret,pc.discount, pc.idPozContract, c.idContract, idPozDoc=0, Nivel=0
from PozContracte pc join Contracte c on c.idContract=pc.idContract
where c.tip='CL'
union all
select c.tip,c.numar,c.tert,c.data,pc.cod,pc.cantitate,pc.pret,pc.discount, pc.idPozContract, c.idContract, lc.idPozDoc, nivel=Nivel+1
from LegaturiContracte lc 
	join cl on cl.idPozContract=lc.idPozContract
	join PozContracte pc on pc.idPozContract=lc.idPozContractCorespondent
	join Contracte c on c.idContract=pc.idContract
where lc.idPozContractCorespondent is not null 
	and Nivel<10
union all
select c.tip,c.numar,c.tert,c.data,pc.cod,pc.cantitate,pc.pret,pc.discount, pc.idPozContract, c.idContract, lc.idPozDoc, nivel=nivel+1
from LegaturiContracte lc 
	join cl on cl.idPozContract=lc.idPozContractCorespondent
	join PozContracte pc on pc.idPozContract=lc.idPozContract
	join Contracte c on c.idContract=pc.idContract
where lc.idPozContractCorespondent is not null 
	and Nivel<10 
union all
select pd.tip,pd.numar,pd.tert,pd.data,pd.cod,pd.cantitate,pd.Pret_valuta,pd.discount, cl.idPozContract, cl.idContract, pd.idPozDoc, Nivel=Nivel+1
from LegaturiContracte lc join cl on cl.idPozContract=lc.idPozContract
	join pozdoc pd on lc.idPozDoc=pd.idPozDoc
where cl.idPozDoc is not null
	and Nivel<10
)
select * from cl where cl.tip='AP'
*/
--select * from LegaturiContracte
GO
--/*pt TESTE decomenteaza aceasta linie
ALTER procedure yso_rapLegaturiContracte --*/ declare
	@Data_inf_perioada datetime, @Data_sup_perioada datetime, @Tip_contract varchar(2)=NULL, @Numar_contract varchar(20)=NULL
	, @Loc_de_munca varchar(10)=NULL, @Tert varchar(20)=NULL, @Termen datetime=NULL, @Stare varchar(1)=NULL
/* si comenteaza aceasta linie pt TESTE
select @Data_inf_perioada='2013-10-01 00:00:00',@Data_sup_perioada='2014-01-31 00:00:00',@Tip_contract='CL',@Numar_contract=NULL
	,@Loc_de_munca=NULL,@Tert=NULL,@Termen=NULL,@Stare=NULL
--*/as

if OBJECT_ID('tempdb..#contracte') is not null drop table #contracte

select *
into #contracte
from Contracte c 
	cross apply (select top 1 st.denumire as denstare, st.stare as stare, st.culoare as culoare, st.facturabil, st.inchisa
		from JurnalContracte j 
			inner join StariContracte st on st.stare = j.stare
		where j.idContract = c.idContract and st.tipContract = c.tip
		order by j.idJurnal desc) st
where c.data between @Data_inf_perioada and @Data_sup_perioada --and st.inchisa=0
	and (c.loc_de_munca like rtrim(@loc_de_munca)+'%' or ISNULL(@loc_de_munca,'')='') 
	and (c.tert like rtrim(@tert) or ISNULL(@tert,'')='') 
	and (c.numar like '%'+ltrim(rtrim(@Numar_contract))+'%' or ISNULL(@Numar_contract,'')='') 
	and (c.valabilitate=@Termen or @Termen is null)
	and (@Stare is null or st.stare=@Stare)
	
create unique nonclustered index id on #contracte (idContract)

if OBJECT_ID('tempdb..#comenzi') is not null drop table #comenzi

select c.tip, c.numar, c.tert, c.data, p.cod, p.cantitate, p.pret, p.discount
	, idContract=CONVERT(int,c.idContract), c.idContractCorespondent
	, idPozContract=convert(int,p.idPozContract), l.idPozContractCorespondent, Nivel=0
into #comenzi -- select *
from PozContracte p 
	join #contracte c on c.idContract=p.idContract
	outer apply (select top 1 l.* from  LegaturiContracte l join PozContracte pc on pc.idPozContract=l.idPozContractCorespondent
			where p.idPozContract=l.idPozContract and l.idPozContractCorespondent is not null) l
order by p.idPozContract

-- iau toti parintii recursiv
while @@ROWCOUNT>0
begin
	insert #comenzi
	select c.tip, c.numar, c.tert, c.data, p.cod, p.cantitate, p.pret, p.discount
		, c.idContract, c.idContractCorespondent
		, idPozContract=convert(int,z.idPozContractCorespondent), idPozContractCorespondent=l.idPozContractCorespondent, Nivel=z.Nivel+1
	-- select *
	from PozContracte p
		join Contracte c on c.idContract=p.idContract
		cross apply (select top 1 * from #comenzi z where z.idPozContractCorespondent=p.idPozContract and z.idPozContractCorespondent is not null) z
		outer apply (select top 1 l.* from  LegaturiContracte l join PozContracte pc on pc.idPozContract=l.idPozContractCorespondent
			where p.idPozContract=l.idPozContract and l.idPozContractCorespondent is not null) l
where z.idPozContractCorespondent not in (select idPozContract from #comenzi)
end

iau_copiii_recursiv:
insert #comenzi
select c.tip, c.numar, c.tert, c.data, p.cod, p.cantitate, p.pret, p.discount
	, c.idContract, c.idContractCorespondent
	, idPozContract=convert(int,p.idPozContract), idPozContractCorespondent=isnull(l.idPozContractCorespondent,0), Nivel=z.Nivel+1
	-- select *
from LegaturiContracte l 
	join #comenzi z on z.idPozContract=l.idPozContractCorespondent 
	join PozContracte p on p.idPozContract=l.idPozContract
	join Contracte c on c.idContract=p.idContract
where l.idPozContract not in (select idPozContract from #comenzi)


while @@ROWCOUNT>0
begin
	goto iau_copiii_recursiv
end

insert #comenzi
select pd.tip, pd.numar, pd.tert, pd.data, pd.cod, pd.cantitate, pd.Pret_valuta, pd.discount
	, idContract=convert(int,-d.idDoc), idContractCorespondent=z.idContract
	, idPozContract=convert(int,-pd.idPozDoc), idPozContractCorespondent=l.idPozContract, Nivel=z.Nivel+1
from LegaturiContracte l 
	join #comenzi z on z.idPozContract=l.idPozContract
	join pozdoc pd on l.idPozDoc=pd.idPozDoc
	join doc d on d.Subunitate=pd.Subunitate and d.Tip=pd.Tip and d.Numar=pd.Numar and d.Data=pd.Data 
where l.idPozDoc is not null

select * from #comenzi z 