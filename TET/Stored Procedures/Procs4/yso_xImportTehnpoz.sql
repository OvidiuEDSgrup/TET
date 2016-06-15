create procedure yso_xImportTehnpoz as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try
/*
	select isnull(Cod_tehn,'') as Cod_tehn, isnull(Den_tehn,'') as Den_tehn, isnull(Tip,'') as Tip, isnull(Den_tip,'') as Den_tip, isnull(Cod,'') as Cod, isnull(Den_cod,'') as Den_cod, isnull(Nr,'') as Nr, isnull(Tip_resursa,'') as Tip_resursa, isnull(Den_tip_resursa,'') as Den_tip_resursa, isnull(Consum_specific,'') as Consum_specific
	,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport
*/
	select distinct Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select			Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific
	from yso_vIaTehnpoz
