--***
create procedure wStergDevizLucru @sesiune varchar(50), @parXML xml 
as

Declare @sub char(9), @mesajeroare varchar(100), @iDoc int, @eroare xml 

--exec luare_date_par 'GE', 'SUBPRO', 0,0,@Sub output 

begin try
	exec sp_xml_preparedocument @iDoc output, @parXML  
	    
	select @mesajeroare=(case when exists (select 1 from pozdevauto pd, OPENXML (@iDoc, '/row')  
		WITH (
		Cod_deviz char(20) '@nrdeviz'
		) as dx  
		where pd.Cod_deviz=dx.Cod_deviz) 
		then 'Devizul are pozitii!'
		else '' end)

	if @mesajeroare<>'' 	
		raiserror(@mesajeroare, 11, 1)
	
	delete devauto from devauto d, OPENXML (@iDoc, '/row')  
			WITH (  
			Cod_deviz char(20) '@nrdeviz'
			) as dx  
			where d.Cod_deviz=dx.Cod_deviz

end try

begin catch
	declare @mesaj varchar(255)
	set @mesaj = /*'(wStergDevizLucru) '+*/ERROR_MESSAGE() 
	raiserror(@mesajeroare, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 

begin catch 
end catch
