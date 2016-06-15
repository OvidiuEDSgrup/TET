--***
CREATE procedure corect_expval as
begin 
	declare @dataimpl datetime
	select @dataimpl=convert(datetime,convert(varchar(4),p1.val_numerica)+'-'+convert(varchar(2),p2.val_numerica)+'-1')
		from par p1, par p2 where p1.tip_parametru='GE' and p1.parametru like 'anulimpl' and p2.tip_parametru='GE' 
		and p2.parametru like 'lunaimpl'
		set @dataimpl=dateadd(d,-1,dateadd(M,1,@dataimpl))
		 delete from expval where data=@dataimpl and exists 
				(select 1 from expval e where e.cod_indicator=expval.cod_indicator and e.tip=expval.tip and e.data=dateadd(d,1,expval.data))
		 update expval set data=dateadd(d,-1,data) where data=dateadd(d,1,@dataimpl)
end
