/*
declare @datajos datetime,@datasus datetime,@cod nvarchar(4000),@grupa_cod nvarchar(4000),@ctert nvarchar(4000),@gtert nvarchar(4000),@comanda nvarchar(4000),@gestiune nvarchar(4000),@datajost nvarchar(4000),@datasust nvarchar(4000),@stare nvarchar(4000),@benef nvarchar(1)
select @datajos='2001-01-01 00:00:00',@datasus='2011-02-01 00:00:00',@cod=NULL,@grupa_cod=NULL,@ctert=NULL,--@gtert='cab',
@comanda=NULL,
@datajost=NULL,@datasust=NULL,@stare=NULL,
@benef=N'B'
--*/

DECLARE @datajos datetime,@datasus datetime,@cod nvarchar(4000),@grupa_cod nvarchar(4000),@ctert nvarchar(4000),@gtert nvarchar(4000)
,@comanda nvarchar(4000),@gestiune nvarchar(4000),@datajost nvarchar(4000),@datasust nvarchar(4000),@stare nvarchar(4000),@benef nvarchar(1)
select @datajos='2012-03-01 00:00:00',@datasus='2012-03-31 00:00:00',@cod=NULL,@grupa_cod=NULL,@ctert=NULL,@gtert=NULL,@comanda=NULL
,@gestiune=NULL,@datajost=NULL,@datasust=NULL,@stare=NULL,@benef=N'F'

declare @q_datajos datetime, @q_datasus datetime, @q_cod varchar(20), @q_grupa_cod varchar(13),
		@q_tert varchar(13), @q_gtert varchar(300),@q_comanda varchar(20),@q_gestiune varchar(13),
		@q_datajost datetime, @q_datasust datetime, @q_stare varchar(1),@q_benef varchar(1)

set		@q_datajos=@datajos set @q_datasus=@datasus set @q_cod=@cod set @q_grupa_cod=@grupa_cod
		set	@q_tert=@ctert set @q_gtert=@gtert set @q_comanda=@comanda set @q_gestiune=@gestiune
		set	@q_datajost=@datajost set @q_datasust=@datasust set @q_stare=@stare set @q_benef=@benef

	/**	Pregatire filtrare pe proprietati utilizatori*/
declare @fltGstUt int
declare @GestUtiliz table(valoare varchar(200), cod varchar(20))
insert into @GestUtiliz (valoare,cod)
select valoare, cod_proprietate from fPropUtiliz() where cod_proprietate='GESTIUNE' and valoare<>''
set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)
declare @eLmUtiliz int
declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
insert into @LmUtiliz(valoare, cod_proprietate)
select valoare, cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)


select p.tert, rtrim(t.denumire) as nume_tert,RTRIM(t.judet) as jud_tert,p.cod,rtrim(n.denumire) as nume_cod,n.um
	,p.cantitate,n.um_1 as um2,
	(case when isnull(n.coeficient_conversie_1,0)=0 then '' else p.cantitate/n.coeficient_conversie_1 end) as cant_um2
	,p.cant_realizata,
	c.data,p.contract as comanda,rtrim(c.explicatii) as explicatii,p.pret,p.pret*p.cantitate as valoare,p.Termen,
	--REPLACE(isnull((select  rtrim(ltrim(pa.comanda_livrare)) as [data()] from pozaprov pa 
	--where pa.Furnizor=p.Tert and pa.Contract=p.Contract and pa.Data=p.Data and pa.Cod=p.Cod and pa.Comanda_livrare<>''
	--for XML path('')),''),' ','; ') as comanda_legatura,
	CASE ISNUMERIC(pe.Explicatii) WHEN 1 THEN CONVERT(int,pe.Explicatii) ELSE 0 END as atp
	,pd.Numar as nr_doc, pd.Data as data_doc, pd.Cantitate as cant_doc, n.grupa, g.Denumire as den_grupa
from pozdoc pd
	inner join pozcon p on p.Subunitate=pd.Subunitate 
		and p.Tip='FC' and p.Contract=pd.Contract and p.Cod=pd.Cod
	left join con c on p.subunitate=c.subunitate and c.contract=p.contract and c.tert=p.tert
	left join pozcon pc on pc.Subunitate=p.Subunitate and pc.Tip='FA' and pc.Tert=p.Tert 
		and pc.Contract=isnull(nullif(c.Contract_coresp,'')
			,(select top 1 fa.contract from pozcon fa where fa.Subunitate=p.Subunitate and fa.Tip='FA' and fa.Tert=p.Tert 
				and fa.Cod=p.Cod))
	left join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=pc.Tip and pe.Contract=pc.Contract and pe.Tert=pc.Tert 
		and pe.Data=pc.Data and pe.Cod=pc.Cod      
	left join terti t on p.tert=t.tert and p.subunitate=t.subunitate and (@q_gtert is null or t.grupa=@q_gtert)
	left join nomencl n on n.cod=p.cod and (@q_gestiune is null or @q_gestiune=n.gestiune)
	left join grupe g on g.Grupa=n.Grupa
where pd.tip='RM' and (p.tip='BK' or p.tip='FC') and left(p.tip,1)=left(c.tip,1)
and pd.data between @q_datajos and @q_datasus and (@q_cod is null or p.cod=@q_cod) and (@q_grupa_cod is null or n.grupa=@q_grupa_cod) and
	(@q_tert is null or @q_tert=p.tert) and (@q_gtert is null or t.grupa is not null) 
	and (@q_comanda is null or @q_comanda=p.contract) and
	(@q_gestiune is null or n.gestiune is not null) and 
	(@q_datajost is null or @q_datasust is null or p.termen between @q_datajost and @q_datasust)
	and (@q_stare is null or c.stare=@q_stare) and (left(c.tip,1)=@q_benef or @q_benef='T')
	and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=n.gestiune))
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=c.Loc_de_munca))
	--and t.grupa is null
order by p.Tert,n.Grupa,p.Cod,p.Contract,pd.Data
	
/***	Obs: filtrarea pe grupa si pe gestiune e mai ciudat facuta deoarece viteza este mult mai buna asa
	(de la un minut la 2 sec pe datele de test, un minut daca s-ar filtra in where si nu in conditiile de left join)
*/