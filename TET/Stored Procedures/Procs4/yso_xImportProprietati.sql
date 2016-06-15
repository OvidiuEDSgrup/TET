create procedure yso_xImportProprietati as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try

	select 	
		Cod=isnull(Cod,'')
		,Denumire_cod=isnull(Denumire_cod,'')
		,Cod_proprietate=isnull(Cod_proprietate,'')
		,Valoare=isnull(Valoare,'')
		,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport

	select distinct 
		Cod
		,Denumire_cod
		,Cod_proprietate
		,Valoare
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select	
		Cod
		,Denumire_cod
		,Cod_proprietate
		,Valoare
	from yso_vIaProprietati
