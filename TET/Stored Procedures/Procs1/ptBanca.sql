CREATE procedure [dbo].[ptBanca](@cTerm char(8))
as
begin
if exists(select name from sysobjects where name='TabelaptBanca')
 truncate table TabelaptBanca
else
 create table TabelaptBanca
 (sold float,codbanca char(30),cont_in_banca char(30),tert char(13),fact_pe_sold char(80),dentert char(50),
 conttert char(50),filiala char(60),banca char(60),contract char(13),suma char(50),cont_beneficiar char(50),datastring char(20),
 total float,nrpoz int,pozitie int identity,terminal char(8))

declare @nTotal float,@nNrPoz float

insert into TabelaptBanca
(sold,codbanca,cont_in_banca,tert,fact_pe_sold,dentert,conttert,filiala,banca,contract,suma,cont_beneficiar,datastring,terminal)
SELECT sum(ft.total-ft.achitat) as sold, 
left(max(t.banca),50) as codbanca, 
left(max(t.cont_in_banca),50) as cont_in_banca, 
f.tert as tert, 
left(dbo.facturi_pe_sold(ft.tert,avnefac.data),80) as fact_pe_sold,
left(max(t.denumire),50) as dentert, 
'/'+left(max(t.cont_in_banca),49) as conttert, 
max(b.filiala) as filiala, max(b.denumire) as denbanca, 
max(avnefac.contractul) as contract, 
convert(char(6),getdate(),12)+'RON'+ltrim(convert(char(20),CONVERT(MONEY,sum(ft.total-ft.achitat)))) as suma, 
--(select count(*) from (SELECT distinct f1.tert FROM dbo.fTert(null,NULL,NULL,null) ft1,facturi f1,terti t1,bancibnr b1 WHERE ft1.tert=f1.tert and ft1.factura=f1.factura and t1.denumire<t.denumire and ft1.tert=t1.tert and t1.banca=b1.cod and f1.data_scadentei<avnefac.data and t1.tert_extern=0 group by avnefac.data,f1.tert,t1.banca,ft1.tert having sum(ft1.total-ft1.achitat)>0.05) as q) as C13, 
max(avnefac.cont_beneficiar) as cont_beneficiar, 
--(select count(*) from (SELECT distinct f.tert FROM dbo.fTert(null,NULL,NULL,null) ft,facturi f,terti t,bancibnr b WHERE ft.tert=f.tert and ft.factura=f.factura and ft.tert=t.tert and t.banca=b.cod and f.data_scadentei<avnefac.data and t.tert_extern=0 group by avnefac.data,f.tert,t.banca,ft.tert having sum(ft.total-ft.achitat)>0.05) as q) as C15, 
--convert(money,(select sum(ttt)from (SELECT f.tert,sum(ft.total-ft.achitat) as ttt FROM dbo.fTert(null,NULL,NULL,null) ft,facturi f,terti t,bancibnr b WHERE ft.tert=f.tert and ft.factura=f.factura and ft.tert=t.tert and t.banca=b.cod and f.data_scadentei<avnefac.data and t.tert_extern=0 group by avnefac.data,f.tert,t.banca,ft.tert having sum(ft.total-ft.achitat)>0.05) as q)) as C16, 
convert(char(6),getdate(),12)+'01' as datastring,@cTerm
--into tempdb..ccc
FROM dbo.fTert(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL) ft,avnefac,facturi f,terti t,bancibnr b WHERE ft.tert=f.tert and ft.factura=f.factura and ft.tert=t.tert and t.banca=b.cod and f.data_scadentei<avnefac.data and t.tert_extern=0 AND abs(AVNEFAC.TERMINAL)=@cTerm group by avnefac.data,f.tert,t.banca,ft.tert,t.denumire 
having sum(ft.total-ft.achitat)>0.05 order by t.denumire

set @nTotal=(select sum(round(sold,2)) from TabelaptBanca)
set @nNrPoz=(select count(*) from TabelaptBanca)

update TabelaptBanca set total=@nTotal,nrPoz=@nNrPoz
end
