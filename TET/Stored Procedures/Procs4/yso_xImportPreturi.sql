create procedure yso_xImportPreturi as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try

	select 	
		cod=ISNULL(cod,'')
		,dencod=ISNULL(dencod,'')
		,catpret=ISNULL(catpret,'')
		,dencategpret=ISNULL(dencategpret,'')
		,tippret=ISNULL(tippret,'')
		,dentippret=ISNULL(dentippret,'')
		,data_inferioara=ISNULL(data_inferioara,'')
		,data_superioara=ISNULL(data_superioara,'')
		,pret_vanzare=ISNULL(pret_vanzare,'')
		,pret_cu_amanuntul=ISNULL(pret_cu_amanuntul,'')
		,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport

	select distinct 
		cod
		,catpret
		,tippret
		,data_inferioara
		,data_superioara
		,pret_vanzare
		,pret_cu_amanuntul
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select	
		cod
		,catpret
		,tippret
		,data_inferioara
		,data_superioara
		,pret_vanzare
		,pret_cu_amanuntul
	from yso_vIaPreturi
