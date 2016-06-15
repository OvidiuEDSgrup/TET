--***
create procedure balanta_centralizatoare @ContJos varchar(40),@ContSus varchar(40),@pLuna int,@pAn int
as
declare @cSubunitate char(9),@IFN int,@dData_inc_an datetime,@dData_sf_luna datetime,@dData_lunii datetime,@cHostID char(8)
exec luare_date_par 'GE','SUBPRO',0,0,@cSubunitate OUTPUT
exec luare_date_par 'GE','IFN',@IFN output,0,''
Set @dData_lunii=cast(@pAn as char(4))+'/'+rtrim(cast(@pLuna as char(2))) +'/01'
Set @dData_inc_an=Dateadd(month,-(@pLuna-1),@dData_lunii)
Set @dData_sf_luna=dateadd(day,-1,Dateadd(month,1,@dData_lunii))
Set @cHostID= isnull((select convert(char(8),abs(convert(int,host_id())))),'')

create table #balcentr
(
HostID char(8),Subunitate char(9),Cont varchar(40),Denumire_cont char(80),
SoldIncAnDBlei float,SoldIncAnCRlei float,RulPrecDBlei float,RulPrecCRlei float,SoldPrecDBlei float,SoldPrecCRlei float,SumePrecDBlei float,SumePrecCRlei float,RulCurDBlei float,RulCurCRlei float,RulCumDBlei float,RulCumCRlei float,TotSumeDBlei float,TotSumeCRlei float,SoldCurDBlei float,SoldCurCRlei float,
SoldIncAnDBval float,SoldIncAnCRval float,RulPrecDBval float,RulPrecCRval float,SoldPrecDBval float,SoldPrecCRval float,SumePrecDBval float,SumePrecCRval float,RulCurDBval float,RulCurCRval float,RulCumDBval float,RulCumCRval float,TotSumeDBval float,TotSumeCRval float,SoldCurDBval float,SoldCurCRval float,
SoldIncAnDBlv float,SoldIncAnCRlv float,RulPrecDBlv float,RulPrecCRlv float,SoldPrecDBlv float,SoldPrecCRlv float,SumePrecDBlv float,SumePrecCRlv float,RulCurDBlv float,RulCurCRlv float,RulCumDBlv float,RulCumCRlv float,TotSumeDBlv float,TotSumeCRlv float,SoldCurDBlv float,SoldCurCRlv float
)

insert #balcentr
select distinct @cHostID,r.subunitate,r.cont,c.denumire_cont,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
from rulaje r,conturi c
where r.subunitate=@cSubunitate and r.data between @dData_inc_an and @dData_sf_luna and r.subunitate=c.subunitate and r.cont=c.cont

declare @valuta char(3),@inValuta int,@curs float

declare #tmpval cursor for
	select distinct valuta
	from rulaje 
	where data between @dData_inc_an and @dData_sf_luna
	order by valuta
open #tmpval
fetch next from #tmpval into @valuta
while @@fetch_status=0
begin
	set @inValuta=(case when @valuta='' then 0 else 1 end)
	-- pentru a avea soldurile si rulajele corecte in RON din valuta pe fiecare luna,
	-- nu mai facem conversia la RON aici, ci direct in procedura calcul_balanta
	-- !!!Pentru MFG - si mai nou pt. toate IFN-urile - calculam toate sumele la cursul de final de luna - asa cum am facut initial
	set @curs=(case when @inValuta=0 /*or 1=1*/ then 1 else isnull((select top 1 curs.curs from curs where curs.valuta=@valuta and curs.data<=@dData_sf_luna order by curs.data desc),0) end)
	
	--> in baza parametrului CIFNDEC se va folosi cursul din decembrie pentru a calcula cursul de inceput de an:
		declare @CIFNDEC int, @curs_init float, @decembrieAnulTrecut datetime
		select @CIFNDEC=isnull((select top 1 val_logica from par where parametru ='CIFNDEC' and tip_parametru='GE'),0)
		set @curs_init=@curs
		if (@CIFNDEC=1 and @inValuta<>0) 
		begin	--dateadd(d,1-day(@dData_sf_luna),@dData_sf_luna)
			set @decembrieAnulTrecut=dateadd(M,1-month(@dData_sf_luna),@dData_sf_luna)
			set @decembrieAnulTrecut=dateadd(d,-day(@decembrieAnulTrecut),@decembrieAnulTrecut)
			set @curs_init=isnull((select top 1 curs.curs from curs where curs.valuta=@valuta and curs.data<=@decembrieAnulTrecut order by curs.data desc),0)
		end
	if not (@inValuta=1 and @curs=0)
	begin
		exec calcul_balanta @pLuna, @pAn, 0, 0, @inValuta, 0, @valuta, /*0*/1,''
		
		update #balcentr
		set
			SoldIncAnDBlei=t.SoldIncAnDBlei+(case when @valuta='' then b.Sold_inc_an_debit else 0 end),
			SoldIncAnCRlei=t.SoldIncAnCRlei+(case when @valuta='' then b.Sold_inc_an_credit else 0 end),
			RulPrecDBlei= t.RulPrecDBlei+(case when @valuta='' then b.Rul_prec_debit else 0 end),
			RulPrecCRlei= t.RulPrecCRlei+(case when @valuta='' then b.Rul_prec_credit else 0 end),
			SoldPrecDBlei= t.SoldPrecDBlei+(case when @valuta='' then b.Sold_prec_debit else 0 end),
			SoldPrecCRlei= t.SoldPrecCRlei+(case when @valuta='' then b.Sold_prec_credit else 0 end),
			SumePrecDBlei= t.SumePrecDBlei+(case when @valuta='' then b.Total_sume_prec_debit else 0 end),
			SumePrecCRlei= t.SumePrecCRlei+(case when @valuta='' then b.Total_sume_prec_credit else 0 end),
			RulCurDBlei= t.RulCurDBlei+(case when @valuta='' then b.Rul_curent_debit else 0 end),
			RulCurCRlei= t.RulCurCRlei+(case when @valuta='' then b.Rul_curent_credit else 0 end),
			RulCumDBlei= t.RulCumDBlei+(case when @valuta='' then b.Rul_cum_debit else 0 end),
			RulCumCRlei= t.RulCumCRlei+(case when @valuta='' then b.Rul_cum_credit else 0 end),
			TotSumeDBlei= t.TotSumeDBlei+(case when @valuta='' then b.Total_sume_debit else 0 end),
			TotSumeCRlei= t.TotSumeCRlei+(case when @valuta='' then b.Total_sume_credit else 0 end),
			SoldCurDBlei= t.SoldCurDBlei+(case when @valuta='' then b.Sold_cur_debit else 0 end),
			SoldCurCRlei= t.SoldCurCRlei+(case when @valuta='' then b.Sold_cur_credit else 0 end),
			SoldIncAnDBval=t.SoldIncAnDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Sold_inc_an_debit*@curs_init),2) else 0 end),
			SoldIncAnCRval=t.SoldIncAnCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Sold_inc_an_credit*@curs_init),2) else 0 end),
			RulPrecDBval= t.RulPrecDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Rul_prec_debit*@curs),2) else 0 end),
			RulPrecCRval= t.RulPrecCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Rul_prec_credit*@curs),2) else 0 end),
			SoldPrecDBval= t.SoldPrecDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Sold_prec_debit*@curs),2) else 0 end),
			SoldPrecCRval= t.SoldPrecCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Sold_prec_credit*@curs),2) else 0 end),
			SumePrecDBval= t.SumePrecDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Total_sume_prec_debit*@curs),2) else 0 end),
			SumePrecCRval= t.SumePrecCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Total_sume_prec_credit*@curs),2) else 0 end),
			RulCurDBval= t.RulCurDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Rul_curent_debit*@curs),2) else 0 end),
			RulCurCRval= t.RulCurCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Rul_curent_credit*@curs),2) else 0 end),
			RulCumDBval= t.RulCumDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Rul_cum_debit*@curs),2) else 0 end),
			RulCumCRval= t.RulCumCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Rul_cum_credit*@curs),2) else 0 end),
			TotSumeDBval= t.TotSumeDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Total_sume_debit*@curs),2) else 0 end),
			TotSumeCRval= t.TotSumeCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Total_sume_credit*@curs),2) else 0 end),
			SoldCurDBval= t.SoldCurDBval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Sold_cur_debit*@curs),2) else 0 end),
			SoldCurCRval= t.SoldCurCRval+(case when @valuta<>'' then round(convert(decimal(15,3),b.Sold_cur_credit*@curs),2) else 0 end)
		from #balcentr t,balanta b
		where t.HostID=@cHostID and b.HostID=t.HostID and b.subunitate=t.subunitate and b.cont=t.cont
	end
	
	fetch next from #tmpval into @valuta
end

close #tmpval
deallocate #tmpval

update #balcentr
set 
	SoldIncAnDBval=(case when SoldIncAnDBval-SoldIncAnCRval > 0 then SoldIncAnDBval-SoldIncAnCRval else 0 end),
	SoldIncAnCRval=(case when SoldIncAnCRval-SoldIncAnDBval > 0 then SoldIncAnCRval-SoldIncAnDBval else 0 end),
	SoldPrecDBval=(case when SoldPrecDBval-SoldPrecCRval > 0 then SoldPrecDBval-SoldPrecCRval else 0 end),
	SoldPrecCRval=(case when SoldPrecCRval-SoldPrecDBval > 0 then SoldPrecCRval-SoldPrecDBval else 0 end),
	SoldCurDBval=(case when SoldCurDBval-SoldCurCRval > 0 then SoldCurDBval-SoldCurCRval else 0 end),
	SoldCurCRval=(case when SoldCurCRval-SoldCurDBval > 0 then SoldCurCRval-SoldCurDBval else 0 end)
from #balcentr b,conturi c
where b.HostID=@cHostID and 
b.subunitate=c.subunitate and b.cont=c.cont and c.tip_cont='B'

update #balcentr
set 
	SoldIncAnDBlv=SoldIncAnDBlei+SoldIncAnDBval,
	SoldIncAnCRlv=SoldIncAnCRlei+SoldIncAnCRval,
	RulPrecDBlv=RulPrecDBlei+RulPrecDBval,
	RulPrecCRlv=RulPrecCRlei+RulPrecCRval,
	SoldPrecDBlv=SoldPrecDBlei+SoldPrecDBval,
	SoldPrecCRlv=SoldPrecCRlei+SoldPrecCRval,
	SumePrecDBlv=SumePrecDBlei+SumePrecDBval,
	SumePrecCRlv=SumePrecCRlei+SumePrecCRval,
	RulCurDBlv=RulCurDBlei+RulCurDBval,
	RulCurCRlv=RulCurCRlei+RulCurCRval,
	RulCumDBlv=RulCumDBlei+RulCumDBval,
	RulCumCRlv=RulCumCRlei+RulCumCRval,
	TotSumeDBlv=TotSumeDBlei+TotSumeDBval,
	TotSumeCRlv=TotSumeCRlei+TotSumeCRval,
	SoldCurDBlv=SoldCurDBlei+SoldCurDBval,
	SoldCurCRlv=SoldCurCRlei+SoldCurCRval
where HostID=@cHostID

update #balcentr
set 
	SoldIncAnDBlv=(case when SoldIncAnDBlv-SoldIncAnCRlv > 0 then SoldIncAnDBlv-SoldIncAnCRlv else 0 end),
	SoldIncAnCRlv=(case when SoldIncAnCRlv-SoldIncAnDBlv > 0 then SoldIncAnCRlv-SoldIncAnDBlv else 0 end),
	SoldPrecDBlv=(case when SoldPrecDBlv-SoldPrecCRlv > 0 then SoldPrecDBlv-SoldPrecCRlv else 0 end),
	SoldPrecCRlv=(case when SoldPrecCRlv-SoldPrecDBlv > 0 then SoldPrecCRlv-SoldPrecDBlv else 0 end),
	SoldCurDBlv=(case when SoldCurDBlv-SoldCurCRlv > 0 then SoldCurDBlv-SoldCurCRlv else 0 end),
	SoldCurCRlv=(case when SoldCurCRlv-SoldCurDBlv > 0 then SoldCurCRlv-SoldCurDBlv else 0 end)
from #balcentr b,conturi c
where b.HostID=@cHostID and 
b.subunitate=c.subunitate and b.cont=c.cont and c.tip_cont='B'

select b.*,c.are_analitice,c.tip_cont,c.cont_parinte,c.apare_in_balanta_sintetica,c.sold_debit as apare_in_balanta_de_raportare
from #balcentr b,conturi c
where b.HostID=@cHostID and b.cont between isnull(@ContJos,'') and isnull(@ContSus,'7Z')
and b.subunitate=c.subunitate and b.cont=c.cont

drop table #balcentr
