--***
create procedure rapAchitarisiCompensariTerti (@datajos datetime,@datasus datetime,
	@sursa varchar(100)='T', @cTert varchar(100)=null, @grupa varchar(100)=null,
	@doc varchar(100)=null, @factura varchar(100)=null, @locm varchar(100)=null,
	@comanda varchar(50)=null,
	@tipuri varchar(500)='PF,PC,PD,PR,PS,IB,IC,ID,IR,IS,CO,SF,IF,FF,FB,CF,CB,C3')
as
begin
	/**	Pregatire filtrare pe lm configurate pe utilizatori*/
	declare @utilizator varchar(20), @eLmUtiliz int
	select @utilizator=dbo.fIaUtilizator('')
	declare @LmUtiliz table(valoare varchar(200))
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare l where utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

declare @flt_comanda bit
select	@tipuri=','+@tipuri+',',
		@flt_comanda=(case when @comanda is null then 0 else 1 end)

select 
pl.Plata_incasare as tip,pl.numar as document,pl.Data,pl.Cont, pl.Cont_corespondent,(case when left(pl.plata_incasare,1)='I' then pl.Suma 
		else 0 end) as Incasari,(case when left(pl.plata_incasare,1)='P' then pl.Suma else 0 end) as Plati,'' as factura_debit,pl.Factura,pl.Loc_de_munca,
		pl.Tert,pl.Explicatii,'P' as [pozplin/pozadoc],t.denumire
from pozplin pl left join terti t on t.tert=pl.tert and pl.subunitate=t.subunitate
where pl.data between @datajos and @datasus and pl.subunitate='1' and (@sursa='T' or @sursa='P')
	and --(pl.plata_incasare in (N'PF',N'PC',N'PD',N'PR',N'PS',N'IB',N'IC',N'ID',N'IR',N'IS',N'CO',N'SF',N'IF',N'FF',N'FB',N'CF',N'CB',N'C3'))
	charindex(','+pl.Plata_incasare+',',@tipuri)>0
	and (pl.tert=@cTert or @cTert is null) and (numar=@doc or @doc is null)
	and (pl.tert in (select tert from terti where grupa=isnull(@grupa,'')) or @grupa is null)
	and (pl.factura=@factura or @factura is null)
	and (@locm is null or pl.Loc_de_munca like @locm+'%')
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=pl.Loc_de_munca))
	and (@flt_comanda=0 or left(pl.Comanda,20)=@comanda)
union all
select pd.tip,pd.numar_document as document,pd.data,pd.cont_deb,pd.cont_cred,pd.suma,0 as Plati,pd.factura_dreapta as factura_debit,
		 pd.factura_stinga as factura_credit,pd.loc_munca,pd.tert,pd.explicatii,'C',t.denumire
from pozadoc pd left join terti t on t.tert=pd.tert and pd.subunitate=t.subunitate
where data between @datajos and @datasus and pd.subunitate='1' and (@sursa='T' or @sursa='C')
	and (pd.tert=@cTert or @cTert is null)
	and (pd.tert in (select tert from terti where grupa=isnull(@grupa,'')) or @grupa is null)
	and /*(pd.tip in (N'PF',N'PC',N'PD',N'PR',N'PS',N'IB',N'IC',N'ID',N'IR',N'IS',N'CO',N'SF',N'IF',N'FF',N'FB',N'CF',N'CB',N'C3'))*/
	charindex(','+pd.tip+',',@tipuri)>0	
	and (numar_document=@doc or @doc is null)
	and (pd.factura_stinga=@factura or pd.factura_dreapta=@factura or @factura is null)
	and (@locm is null or pd.Loc_munca like @locm+'%')
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=pd.Loc_munca))
	and (@flt_comanda=0 or left(pd.Comanda,20)=@comanda)
and pd.subunitate='1'
order by cont,data,plata_incasare
end
