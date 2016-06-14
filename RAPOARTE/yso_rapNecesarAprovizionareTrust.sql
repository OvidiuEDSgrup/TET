declare @gest101 nvarchar(3),@data11 nvarchar(4000),@data12 nvarchar(4000),@data21 nvarchar(4000),@data22 nvarchar(4000)
	,@data31 nvarchar(4000),@data32 nvarchar(4000),@data1 datetime,@data2 datetime,@Tert nvarchar(4000),@cod nvarchar(4000)
	,@grupa nvarchar(4000),@coef nvarchar(1),@stocStrict bit
select @gest101=N'101',@data11=NULL,@data12=NULL,@data21=NULL,@data22=NULL,@data31=NULL,@data32=NULL,@data1='2013-10-01 00:00:00',@data2='2013-10-30 00:00:00',@Tert=NULL,@cod=NULL,@grupa=NULL,@coef=N'1',@stocStrict=0

declare @gestiune char(20)
if(@gest101='101') set @gestiune='101,300'
else set @gestiune=null

select r.* from
(select distinct s.cod as cod,n.Denumire as denumire,
isnull((select Denumire from terti where tert=n.Furnizor),'') as Furnizor,
(select isnull(sum(sl.stoc_min),0) from stoclim sl where sl.cod=s.cod and sl.cod_gestiune='101') as stoc_siguranta,
(select isnull(sum(stoc),0) from stocuri where cod=s.cod) as stocTET,
(select isnull(sum(stoc),0) from stocuri where cod=s.cod and cod_gestiune='101') as stoc101,  --@gest101) as stoc101,
(select isnull(sum(stoc),0) from stocuri where cod=s.cod and cod_gestiune='900') as gest_900,
(select isnull(sum(stoc),0) from stocuri where cod=s.cod and cod_gestiune='500') as gest_500,
(select isnull(sum(stoc),0) from stocuri where cod=s.cod and cod_gestiune='300') as rezerv,
---vanzari 1
(select isnull(sum(cantitate),0) 
	from pozdoc 
	where cod=s.cod and tip in ('AP') and data>=@data11 and data<=@data12  
		  and (isnull(@gestiune, '') = '' OR  Gestiune in (select * from Split(@gestiune,','))) )+
	(select isnull(sum(c.cantitate),0) 
	from pozdoc c,pozdoc pp 
	where  pp.tip='PP' and c.data=pp.data and  c.numar=pp.numar and c.cod=s.cod 
		   and c.tip in ('CM') and c.data>=@data11 and c.data<=@data12 and (isnull(@gestiune, '') = '' 
		   OR  c.Gestiune in (select * from Split(@gestiune,','))) ) as vanz1,
---vanzari 2
(select isnull(sum(cantitate),0) 
	from pozdoc 
	where cod=s.cod and tip in ('AP') and data>=@data21 and data<=@data22  
		  and (isnull(@gestiune, '') = '' OR  Gestiune in (select * from Split(@gestiune,','))) )+
	(select isnull(sum(c.cantitate),0) 
	from pozdoc c,pozdoc pp 
	where  pp.tip='PP' and c.data=pp.data and c.numar=pp.numar and c.cod=s.cod and c.tip in ('CM') 
		   and c.data>=@data21 and c.data<=@data22  and (isnull(@gestiune, '') = '' 
		   OR  c.Gestiune in (select * from Split(@gestiune,','))) ) as vanz2,
---vanzari 3
(select isnull(sum(cantitate),0) 
	from pozdoc 
	where cod=s.cod and tip in ('AP') and data>=@data31 and data<=@data32  
		  and (isnull(@gestiune, '') = '' OR  Gestiune in (select * from Split(@gestiune,','))) )+
	(select isnull(sum(c.cantitate),0) 
	from pozdoc c,pozdoc pp 
	where  pp.tip='PP' and c.data=pp.data  and c.numar=pp.numar and c.cod=s.cod and c.tip in ('CM') 
		   and c.data>=@data31 and c.data<=@data32  and (isnull(@gestiune, '') = '' 
		   OR  c.Gestiune in (select * from Split(@gestiune,','))) ) as vanz3,
-----
/*
(select isnull(sum(cantitate),0) from pozdoc where cod=s.cod and tip in ('AP','CM') and data>=@data21 and data<=@data22 and (isnull(@gestiune, '') = '' OR  Gestiune in (select * from Split(@gestiune,','))) ) as vanz2,
(select isnull(sum(cantitate),0) from pozdoc where cod=s.cod and tip in ('AP','CM') and data>=@data31 and data<=@data32 and (isnull(@gestiune, '') = '' OR  Gestiune in (select * from Split(@gestiune,','))) ) as vanz3,
*/
0 as necesarAprovizionat,
(select isnull(SUM(cantitate-cant_realizata),0) 
	from pozcon 
	where tip='FC' and Contract in (select contract 
									from con 
									where  tip='FC'and stare ='1' and DATA>=@data1 and DATA<=@data2 
									and  (isnull(@Tert, '') = '' OR  tert = rtrim(rtrim(@Tert))))
									and DATA>=@data1 and DATA<=@data2 and cod=s.cod ) as com_def_Incurs,
(select isnull(SUM(cantitate-cant_realizata),0) 
	from pozcon 
	where tip='FC' and Contract in (select contract 
									from con 
									where  tip='FC'and stare ='0' and DATA>=@data1 and DATA<=@data2 
									and  (isnull(@Tert, '') = '' OR  tert = rtrim(rtrim(@Tert))))
									and DATA>=@data1 and DATA<=@data2 and cod=s.cod ) as com_oper_Incurs
from stocuri s, nomencl n
where s.Cod=n.cod and n.Tip<>'U'
and (isnull(@cod, '') = '' OR  s.cod= rtrim(rtrim(@cod)))
and  (isnull(@grupa, '') = '' OR  n.grupa = rtrim(rtrim(@grupa)))
and (isnull(@Tert, '') = '' OR  n.Furnizor = rtrim(rtrim(@Tert)))
)r
where((r.stoc_siguranta +r.vanz1*cast(@coef as float)+r.rezerv)-r.stoc101-r.gest_900-r.gest_500-r.com_def_Incurs-r.com_oper_Incurs)>0
and (@stocStrict=0 or r.stoc_siguranta>0) 