create procedure yso_xImportTerti as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try--*/declare @tabela varchar(255)='stoclim', @fisier nvarchar(4000)='\\10.0.0.10\import\testimport.xlsx' 

	select distinct /*Subunitate,Tip_gestiune,*/Cod_gestiune,Cod,Stoc_min,Stoc_max
	into ##importXlsDifTmp
	from ##importXlsTmp
	except
	select			/*Subunitate,Tip_gestiune,*/Cod_gestiune,Cod,Stoc_min,Stoc_max
	from yso_vIaStoclim
