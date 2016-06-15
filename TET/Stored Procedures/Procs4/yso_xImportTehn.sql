create procedure yso_xImportTehn as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try
/*
	select isnull(Cod_tehn,'') as Cod_tehn, isnull(Denumire,'') as Denumire, isnull(Tip_tehn,'') as Tip_tehn
	,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport
*/
	select distinct Cod_tehn, Denumire, Tip_tehn
	into ##importXlsDifTmp
	from ##importXlsTmp
	except
	select			Cod_tehn, Denumire, Tip_tehn
	from tehn
