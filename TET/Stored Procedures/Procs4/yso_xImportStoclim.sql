create procedure yso_xImportStoclim as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try--*/declare @tabela varchar(255)='stoclim', @fisier nvarchar(4000)='\\10.0.0.10\import\testimport.xlsx' 
/*
	select Subunitate=isnull(Subunitate,'')
	, Tip_gestiune=isnull(Tip_gestiune,''),Cod_gestiune=isnull(Cod_gestiune,''),Den_gestiune=isnull(Den_gestiune,'')
	, Cod=isnull(Cod,''), Den_cod=isnull(Den_cod,'')
	, Data=isnull(data,'')
	, Stoc_min=isnull(Stoc_min,'')
	, Stoc_max=isnull(Stoc_max,'')
	, Pret=isnull(pret,'')
	, Locatie=isnull(Locatie,'')
	,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport
*/
	select distinct /*Subunitate,Tip_gestiune,*/Cod_gestiune,Cod,Stoc_min,Stoc_max
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select			/*Subunitate,Tip_gestiune,*/Cod_gestiune,Cod,Stoc_min,Stoc_max
	from yso_vIaStoclim
