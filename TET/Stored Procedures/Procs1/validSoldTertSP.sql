
create procedure validSoldTertSP
as
begin try	
	declare
		@err varchar(1000), @bloc_scad int, @zile_intarziere int

	exec luare_date_par 'GE','BLOCSCAD',@bloc_scad OUTPUT, @zile_intarziere OUTPUT, ''

	/*	Daca exista clienti cu scandeta depasita si nu au pusa exceptie	*/
	IF @bloc_scad=1 
		--and EXISTS (select 1 from facturi f join #validSold vs on f.tert=vs.tert and f.tip=0x46 and datediff(DAY, f.data_scadentei, GETDATE()) > @zile_intarziere and vs.sold_max<>999999998 and f.Sold>0.01)
		and EXISTS (select 1 from #validSold vs join #vfacturi f on f.tert=vs.tert and f.sold>0.01 and f.data_scadentei<convert(date,getdate())
			/*SP*/ and vs.valoare>0.01 /*SP*/)
		RAISERROR('Clientul are facturi cu scadenta depasita! Nu este permisa emiterea de noi facturi!', 16,1)
	
	update f set data_scadentei=getdate()
	from #validSold vs join #vfacturi f on f.tert=vs.tert and f.sold>0.01 and f.data_scadentei<convert(date,getdate())
			/*SP*/ and vs.valoare<0.01 /*SP*/
	
	update f set data_scadentei=getdate()
	from #validSold vs join #vfacturi f on f.tert=vs.tert and f.sold>0.01 and f.data_scadentei<convert(date,getdate())
			/*SP*/ and isnull(@bloc_scad,0)<>1 
			
	update vs set valoare=sold_max-(valoare+sold)
	from #validSold vs where valoare+sold>sold_max and valoare<0
	
	--truncate table #validSold		
end try
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH