--***
create procedure [dbo].[wStergDevizeLucru] @sesiune varchar(50), @parXML xml 

as

Declare @cSub char(9), @mesajeroare varchar(100), @eroare xml 
exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output 

begin try

	declare @iDoc int 
	exec sp_xml_preparedocument @iDoc output, @parXML  
	    
	select @mesajeroare= 
	(case 
	-- are pozitii
	when exists (select 1 from pozdevauto pd, OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  Cod_deviz char(9) '@coddeviz',   
      Tip_resursa char(10) '@tipresursa',
	  Marca varchar(20) '@marca',
	  Pret_vanzare float(20)'@pretvanzare'
	 ) as dx  
	where pd.Cod_deviz=dx.Cod_deviz and pd.Tip_resursa=dx.Tip_resursa and pd.Marca=dx.Marca and pd.Pret_vanzare=convert(varchar(20),dx.Pret_vanzare,103)) 
		then 'Devizul are pozitii!'
	else '' end)

	if @mesajeroare<>'' 	
		raiserror(@mesajeroare, 11, 1)

	delete devauto from devauto d, OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  Cod_deviz char(9) '@coddeviz',   
	  Data_lansarii datetime '@datalansarii', 
	  Data_inchiderii datetime '@datainchiderii',
      Executant char(10) '@executant',
	  Beneficiar varchar(20) '@beneficiar',
	  Valoare_deviz float(20)'@valoaredeviz',
	  KM_bord float(20) '@kmbord'
	 ) as dx  
	 
where d.Cod_deviz=dx.Cod_deviz and d.Executant=dx.Executant and d.Beneficiar=dx.Beneficiar 
  and d.Data_lansarii=convert(varchar(20),dx.Data_lansarii,103) and d.Data_inchiderii=convert(varchar(20),dx.Data_inchiderii,103)
  and d.Valoare_deviz=convert(varchar(20),dx.Valoare_deviz,103)  and d.KM_bord=convert(varchar(20), dx.KM_bord,103)

end try
begin catch
	declare @mesaj varchar(255)
	--if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		--set @mesajeroare='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	set @mesaj = ERROR_MESSAGE() 
	raiserror(@mesajeroare, 11, 1)
end catch
