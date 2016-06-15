
create procedure wIaCoduriVamale @sesiune varchar(50), @parXML xml 
as  
begin try
	if exists(select * from sysobjects where name='wIaCoduriVamaleSP' and type='P')
		exec wIaCoduriVamaleSP @sesiune, @parXML 
	else      
	begin
		set transaction isolation level READ UNCOMMITTED
	
		declare @cod varchar(20), @denumire varchar(50), @f_denumire varchar(50), @f_cod varchar(10), @utilizator varchar(20), @mesaj_eroare varchar(500)
    
		select @f_denumire=isnull(@parXML.value('(/row/@f_denumire)[1]','varchar(80)'),''),
			@f_cod=isnull(@parXML.value('(/row/@f_cod)[1]','varchar(20)'),'')

		select RTRIM(cod) as cod, RTRIM(Denumire) as denumire, 
			convert(int,Val1) as tipcod, (case when convert(int,Val1)=0 then 'Cod vamal' else 'Cod nom. combinat' end) as dentipcod, 
			rtrim(UM) as um, rtrim(UM2) as um2, convert(decimal(12,4),Coef_conv) as coefconv, 
			convert(decimal(6,2),Taxa_UE) as taxaue, convert(decimal(6,2),Taxa_AELS) as taxaaels, convert(decimal(6,2),Taxa_GB) as taxagb, 
			convert(decimal(6,2),Taxa_alte_tari) as taxaalte, convert(decimal(6,2),Comision_vamal) as comvamal, 
			convert(decimal(6,2),Randament) as randament, rtrim(Alfa1) as codnc8, rtrim(Alfa2) as um_supl, 
			convert(decimal(15,2),Val2) as val2
		from codvama 
		where isnull(cod,'') like '%'+ISNULL(@f_cod,'')+'%'
			and isnull(Denumire,'') like '%'+ISNULL(@f_denumire,'')+'%'  
		order by cod
		for xml raw
	end
end try
begin catch
	set @mesaj_eroare='(wIaCoduriVamale:) '+ERROR_MESSAGE()
	raiserror(@mesaj_eroare,11,1)
end catch	

		 
