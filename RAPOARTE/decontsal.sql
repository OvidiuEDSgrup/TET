--create proc yso_rapDecontSalariati (@cData datetime='2012-04-05 00:00:00'
--,@marca nvarchar(4000)=NULL
--,@decont nvarchar(4000)
--,@cont nvarchar(4000)
--,@ptrulaj nvarchar(1)
--,@ptfisa nvarchar(1)
--,@datajos nvarchar(4000)
--,@datasus nvarchar(4000)
--,@dDataScadJos nvarchar(4000)
--,@dDataScadSus nvarchar(4000)
--,@pe_sold nvarchar(1)
--,@plecati int) as
declare @cData datetime,@marca nvarchar(4000),@decont nvarchar(4000),@cont nvarchar(4000),@ptrulaj nvarchar(1),@ptfisa nvarchar(1),@datajos nvarchar(4000),@datasus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),@pe_sold nvarchar(1),@plecati int
select @cData='2012-04-05 00:00:00'
,@marca=NULL
,@decont=NULL
,@cont=NULL
,@ptrulaj=N'0'
,@ptfisa=N'0'
,@datajos=NULL
,@datasus=NULL
,@dDataScadJos=NULL
,@dDataScadSus=NULL
,@pe_sold=N'0'
,@plecati=2

select * into #dec from dbo.fdeconturi('1/1/1901', @cData, @marca,@decont,@cont,@ptrulaj,@ptfisa) ft
where ft.data between isnull(@datajos,'1/1/1901') and isnull(@datasus,'1/1/2999') and
 ft.data_scadentei between isnull(@dDataScadJos,'1/1/1901') and isnull(@dDataScadSus ,'1/1/2999')

select p.nume,ft.* 
from #dec ft
inner join (select marca,decont,sum(valoare-achitat) as suma from #dec group by decont,marca) as k
on k.marca=ft.marca and k.decont=ft.decont left outer join personal p on ft.marca=p.marca 
where (@pe_sold=0 or abs(isnull(k.suma,0))>0.009)
and 
((@plecati=1 and loc_ramas_vacant=1 and Data_plec<=@datasus and Data_plec<>'1901-01-01' and Data_plec<>'1900-01-01')
or (@plecati=0 and loc_ramas_vacant=0) or @plecati=2)
/* 
--and ft.subunitate=p.subunitate
--left outer join facturi f on ft.subunitate=f.subunitate and ft.tert=f.tert and ft.factura=f.factura 
--and convert(char(1),f.tip)=(case when ft.tip='F' then 'T' else 'F' end)
--and (@aviz_nefac=0 or rtrim(isnull(f.factura,''))<>'')
--and (@pe_sold=0 or isnull(valoare,0)-isnull(achitat,0)<>0)
*/
order by p.marca,ft.data

drop table #dec