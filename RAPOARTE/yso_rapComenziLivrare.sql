
/****** Object:  StoredProcedure [dbo].[yso_rapComenziLivrare]    Script Date: 01/03/2014 13:32:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--/*pt TESTE decomenteaza aceasta linie
CREATE procedure [dbo].[yso_rapComenziLivrare] --*/ declare
	@Data_inf_perioada datetime, @Data_sup_perioada datetime, @Loc_de_munca varchar(10)=NULL, @Tert varchar(20)=NULL, @Numar_contract varchar(20)=NULL
	, @Termen datetime=NULL, @Stare varchar(1)=NULL
/* si comenteaza aceasta linie pt TESTE
select @Data_inf_perioada='2013-12-01 00:00:00',@Data_sup_perioada='2014-01-31 00:00:00',@Loc_de_munca=NULL,@Tert=NULL,@Numar_contract=NULL,@Termen=NULL,@Stare=NULL
--*/as
declare @mesaj varchar(100), @cuRezContracte bit, @gestRezContracte varchar(200)

select @cuRezContracte=p.Val_logica, @gestRezContracte=rtrim(p.Val_alfanumerica) from par p where p.Tip_parametru='GE' and p.Parametru='REZSTOCBK'

begin try
set transaction isolation level read uncommitted

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

if OBJECT_ID('tempdb..#pozContracte') is not null drop table #pozContracte

select CONVERT(varchar(10), c.data,105 ) as datacomenzii, c.valabilitate as termenlivrare, t.Denumire as client, c.numar as comandalivrare
	, c.idContract, pc.idPozContract
	, c.stare, c.denstare, c.culoare
	, c.gestiune, pc.cod 
	, pc.cantitate*pc.pret as suma, pc.cantitate as cantitateUM1, n.UM as umNom 
	, xc._cantitate2 as cantitateUM2, um2Nom=n.UM_1 
	, pc.pret, convert(float,0) as stocUM1, convert(float,0) as stocUM2
	, pc.cantitate-(case when pd.cantFacturat>pd.cantRezervat then pd.cantFacturat else pd.cantRezervat end) as diferentaUM1
	, xc._cantitate2-(case when pd.cantFacturat2>pd.cantRezervat2 then pd.cantFacturat2 else pd.cantRezervat2 end) as diferentaUM2
	, pd.cantTransferat, pd.cantTransferat2
	, pd.cantFacturat, pd.cantFacturat2
into #pozContracte
from PozContracte as pc 
	cross apply (select _cantitate2=isnull(pc.detalii.value('(/row/@_cantitate2)[1]','float'),0)) xc
	inner join Nomencl as n on pc.cod=n.Cod
	inner join 
		#contracte as c on c.idContract=pc.idContract
	inner join terti as t on t.Subunitate='1' and t.Tert=c.tert		
	outer apply 
		(select sum(cant.rezervat) as cantRezervat, sum(cant.rezervat2) as cantRezervat2
			, sum(cant.transferat) as cantTransferat, sum(cant.transferat2) as cantTransferat2
			, sum(cant.facturat) as cantFacturat, sum(cant.facturat2) as cantFacturat2
		from LegaturiContracte l 
			inner join pozdoc pd on l.idPozDoc=pd.idPozDoc
			cross apply (select _cantitate2=isnull(pc.detalii.value('(/row/@_cantitate2)[1]','float'),0)) xd
			outer apply 
				(select gestRez=sign(charindex(rtrim((case when pd.Cantitate>0 then pd.Gestiune_primitoare else pd.Gestiune end))+';',rtrim(@gestRezContracte)+';'))
				where @cuRezContracte=1) r
			cross apply 
				(select rezervat=(case when pd.Tip='TE' and r.gestRez=1 then pd.Cantitate else 0 end)
					,rezervat2=(case when pd.Tip='TE' and r.gestRez=1 then xd._cantitate2 else 0 end)
					,transferat=(case when pd.Tip='TE' and r.gestRez=0 then pd.Cantitate else 0 end)
					,transferat2=(case when pd.Tip='TE' and r.gestRez=0 then xd._cantitate2 else 0 end)
					,facturat=(case pd.Tip when 'AP' then pd.Cantitate else 0 end)
					,facturat2=(case pd.Tip when 'AP' then xd._cantitate2 else 0 end)) cant
		where l.idPozContract=pc.idPozContract and pd.Tip in ('AP','TE')) pd	
order by c.valabilitate, c.gestiune, pc.cod

create unique nonclustered index con on #pozContracte (termenlivrare, idcontract, idpozcontract)
create nonclustered index cod on #pozContracte (gestiune, cod)


if OBJECT_ID('tempdb..#stocuri') is not null drop table #stocuri

select gestiune=s.Cod_gestiune, s.Cod
	, stoc=sum(s.Stoc), stoc_UM2=sum(s.Stoc_UM2) 
	--, stocRezervat=sum(s.Stoc), stocRezervat_UM2=sum(s.Stoc_UM2) 
into #stocuri
from stocuri s where charindex(rtrim(s.Cod_gestiune)+';',rtrim(@gestRezContracte)+';')=0
group by s.Cod_gestiune, s.Cod
having sum(s.Stoc+s.Stoc_UM2)>=0.001

create unique nonclustered index cod on #stocuri (gestiune, cod)

update c 
set stocUM1=s.stoc, stocUM2=s.stoc_UM2
from #pozContracte c join #stocuri s on s.gestiune=c.gestiune and s.Cod=c.gestiune

select * from #pozContracte c 
order by c.termenlivrare, c.idContract, c.idPozContract

end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1)
end catch
GO


