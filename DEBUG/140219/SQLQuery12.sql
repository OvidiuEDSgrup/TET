select top 100
	rtrim(s.cod_intrare) as cod,
	--ltrim(rtrim(convert(char(18),convert(decimal(12,3),s.stoc))))+' '+n.um+ 
	'Ct. '+rtrim(s.cont)+
		(case when @StocLot=1 and @Iesire=1 then ', Lot: '+isnull(RTRIM(ltrim(s.lot)),'')else '' end)
		 --(case when @DataExp=1 and @Iesire=1 then ', Data exp: '+isnull(convert(char(10),s.Data_expirarii,101),'') 
		 --  	   when @tip in ('CI') then ' Data Exp. '+ convert(char(10),s.Data_expirarii,101) else '' end) 
		 +', '+convert(char(10),s.data,103)
		   	   as info,
	--'Ct. '+rtrim(s.cont)
	rtrim(s.cod_intrare)
	--+', '+convert(char(10),s.data,103)
	+', Pret '+ltrim(rtrim(convert(char(18),convert(decimal(11,5),s.Pret_cu_amanuntul))))
	+', Stoc '+ltrim(rtrim(convert(char(18),convert(decimal(12,3),s.stoc))))+' '+n.um as denumire
	from stocuri s