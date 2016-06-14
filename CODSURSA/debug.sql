select * from pozcon where tip='bk'

	update pozcon set cant_realizata=cant_realizata+@realizat,@gid=1
		where subunitate=@gsub and left(tip,1)=@ctipcontr and contract=@gcontr --and tert=@gtert 
		and cod=@gcod 
		/*and (@rezstoc=0 or @rezstoc=1 and mod_de_plata=@ggest 
			and (left(@gtip,1)='A' or factura=@glocatie) and (left(@gtip,1)='R' or valuta=@gcodi) 
			and zi_scadenta_din_luna=0 and (left(@gtip,1)='R' or contract<>@glocatie))*/
		and ((@ctipcontr = 'B' and tip = 'BK') or (@ctipcontr = 'F' and tip = 'FC') or (@ctipcontr = 'B' and tip = 'BP'))
		and (@multicdbk=0 or @multicdbk=1 and (@ctipcontr<>'B' or abs(pret-@gpret)<=0.001))
		and (@pozsurse=0 or @pozsurse=1 and (@ctipcontr<>'B' or mod_de_plata=@gbarcod))

		@rezstoc	1	int
		@multicdbk	0	int
		@pozsurse	0	int
		@realizat	1.000000000000000e+000	float
		@csub	1        	char
		@ccod	0003000             	char
		@barcod	        	char
		@ctip	AP	char
		@ccontr	8                   	char
		@ctert	0212679091913	char
		@cgest	300      	char
		@semn	1	int
		@cant	1.000000000000000e+000	float
		@ctipcontr	B	char
		@ccodi	TEST10002B   	char
		@clocatie	453567              	char
		@pret	2.700000000000000e+002	float
		@gsub	1        	char
		@gcod	0003000             	char
		@gbarcod	        	char
		@gtip	AP	char
		@gcontr	8                   	char
		@gtert		char
		@ggest	300      	char
		@gcodi	TEST10002B   	char
		@glocatie	453567              	char
		@gid	0	int
		@gpret	0.000000000000000e+000	float
		@gfetch	-1	int
		@cGestPrim		char
		@gGestPrim		char