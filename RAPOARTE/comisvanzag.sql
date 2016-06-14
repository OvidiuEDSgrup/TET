declare @data1 datetime,@data2 datetime,@agent nvarchar(4000),@echipa nvarchar(4000),@client nvarchar(4000)
select @data1='2012-01-01 00:00:00',@data2='2012-05-18 00:00:00',@agent=NULL,@echipa=NULL,@client=NULL

DECLARE @table TABLE
(
	loc_de_munca char(80),
	grupa char(150),
	echipa char(200),
	client char(80),
	suma float,
	targetGrupa float,
	comGrupa float,
	comTert float
)
drop table #teste
--insert into @table
select r.lmt,r.grupat,r.client as clientt,
ltrim(rtrim(r.loc_de_munca))+' - '+(select ltrim(rtrim(denumire)) from lm where cod=r.loc_de_munca) as loc_de_munca,
--max(r.sumaGrupaAgent) as sumaGrupaAgent,
ltrim(rtrim(r.grupa))+' - '+(select ltrim(rtrim(denumire)) from grupe where grupa=r.Grupa) as grupa ,
(select max(valoare) from proprietati where Cod_proprietate='ECHIPA' and tip='TERT' and cod=r.client and Valoare_tupla='') as echipa,
ltrim(rtrim(r.client))+' - '+ltrim(rtrim((select ltrim(rtrim(denumire)) from terti where tert=r.client))) as client, 
SUM(r.cantitate*r.pret_cu_amanuntul) as suma, MAX(r.targetGrupa) as targetGrupa,
 max(r.comGrupa) as comGrupa,
(select valoare from proprietati where Cod_proprietate='RENTABILITATE' and tip='TERT' and cod=r.client) as comTert
into #teste
 from
(select p.cod,p.Cantitate,p.Pret_cu_amanuntul,n.grupa,p.tert as client, p.loc_de_munca as lmt, n.grupa as grupat,
(select MAX(Loc_munca) from infotert where infotert.Subunitate=p.Subunitate and infotert.Tert=p.Tert and infotert.Identificator='') as loc_de_munca,
(select MAX(tert) from pozdoc where tip='RM' and cod=p.Cod) as furnizor,
(select SUM(comision_suplimentar) from targetag where Agent=p.Loc_de_munca and Produs=n.Grupa and Client=p.Tert/*SUBSTRING(n.grupa,1,isnull(nullif(charindex('.',n.grupa),0),1)-1)*/) as targetGrupa,
(select TOP 1 valoare from proprietati where Cod_proprietate='comision' and cod=n.grupa) as comGrupa,
(select SUM(cantitate*pret_cu_amanuntul) from pozdoc where DATA=p.Data and Numar=p.numar and cod=p.cod and Loc_de_munca=p.Loc_de_munca) as sumaGrupaAgent
 from pozdoc p ,nomencl n where p.tip IN ('AP','AC') 
 and p.DATA>=@data1 and p.Data<=@data2 and n.Cod=p.cod)r
--and n.grupa in ('1.11.1.3','1.1.4') 
  --and (@agent is null or p.loc_de_munca=@agent)
 --where r.Loc_de_munca='11112221' and r.grupa='1.1.4'
 group by r.loc_de_munca,r.client,r.grupa
 ,r.lmt,r.grupat
--order by r.loc_de_munca,r.grupa,r.furnizor

--select * from @table

--(select r.loc_munca, SUM(r.suma*(r.comisionProcent/100)) as comIncasare from 
--		(select ltrim(rtrim(pd.Loc_munca))+' - '+(select ltrim(rtrim(denumire)) from lm where cod=pd.Loc_munca) as loc_munca,
--		 pd.Factura,pl.suma,pd.Data as datatDoc,pl.Data as dataplin,
--		DATEDIFF(dd,pd.data,pl.data) as difZi,
--		(case when DATEDIFF(dd,pd.data,pl.data)>=0 and DATEDIFF(dd,pd.data,pl.data) <5  then (select n1 from comisionag where tip_comision=1)
--				when DATEDIFF(dd,pd.data,pl.data) >=5 and  DATEDIFF(dd,pd.data,pl.data)<15 then (select n1 from comisionag where tip_comision=2)
--				when DATEDIFF(dd,pd.data,pl.data) >=15 and  DATEDIFF(dd,pd.data,pl.data)<25 then (select n1 from comisionag where tip_comision=3)
--				when DATEDIFF(dd,pd.data,pl.data) >=25 and  DATEDIFF(dd,pd.data,pl.data)<=30 then (select n1 from comisionag where tip_comision=4) end) as comisionProcent
--		from pozplin pl,doc pd 
--		where pl.factura=pd.factura and pd.tip='AP' and pl.Plata_incasare='IB' and pl.Tert=pd.cod_Tert
--		and pd.data>=@data1 and pd.Data<=@data2
--		/*and DATEDIFF(dd,pd.data,pl.data)<=(select MAX(cast(dep_zile as int)) from comisionag)*/)r
--	group by r.loc_munca)

select t.loc_de_munca ,
	t.grupa ,
	t.echipa,
	t.client,
	t.suma ,
	t.targetGrupa ,
	t.comGrupa ,
	t.comTert,
	(select SUM(suma) from @table where loc_de_munca=t.loc_de_munca and grupa=t.grupa) as sumaGrupaAgent, rez.comIncasare as comIncasare
	from @table t,
	 (select r.loc_munca, SUM(r.suma*(r.comisionProcent/100)) as comIncasare from 
		(select ltrim(rtrim(pd.Loc_munca))+' - '+(select ltrim(rtrim(denumire)) from lm where cod=pd.Loc_munca) as loc_munca,
		 pd.Factura,pl.suma,pd.Data as datatDoc,pl.Data as dataplin,
		DATEDIFF(dd,pd.data,pl.data) as difZi,
		(case when DATEDIFF(dd,pd.data,pl.data)>=0 and DATEDIFF(dd,pd.data,pl.data) <5  then (select n1 from comisionag where tip_comision=1)
				when DATEDIFF(dd,pd.data,pl.data) >=5 and  DATEDIFF(dd,pd.data,pl.data)<15 then (select n1 from comisionag where tip_comision=2)
				when DATEDIFF(dd,pd.data,pl.data) >=15 and  DATEDIFF(dd,pd.data,pl.data)<25 then (select n1 from comisionag where tip_comision=3)
				when DATEDIFF(dd,pd.data,pl.data) >=25 and  DATEDIFF(dd,pd.data,pl.data)<=30 then (select n1 from comisionag where tip_comision=4) end) as comisionProcent
		from pozplin pl,doc pd 
		where pl.factura=pd.factura and pd.tip='AP' and pl.Plata_incasare='IB' and pl.Tert=pd.cod_Tert
		and pd.data>=@data1 and pd.Data<=@data2
		/*and DATEDIFF(dd,pd.data,pl.data)<=(select MAX(cast(dep_zile as int)) from comisionag)*/)r
	group by r.loc_munca)rez
where rez.loc_munca=t.loc_de_munca 
and (isnull(@echipa,'')='' or t.echipa=@echipa)
and (isnull(@agent,'')='' or t.loc_de_munca=@agent)
and (ISNULL(@client,'')='' or t.client=@client)
order by t.echipa,t.loc_de_munca,t.client,t.grupa

select * 
from #teste t join targetag ta on ta.Agent=t.lmt and ta.Client=t.clientt and ta.Produs=t.grupat

select * from targetag ta where  exists 
(select 1 from #teste t where ta.Agent=t.lmt and ta.Client=t.clientt and ta.Produs=t.grupat)
select  t.lmt as Agent, t.clientt as Client, t.grupat as Grupa, '2012-01-01' as Data_lunii, 0 as Comision_suplimentar
from #teste t order by 2 desc