drop view yso_vIaTehn 
go
create view yso_vIaTehn as
select Cod_tehn, Denumire
	, Tip_tehn, CASE t.Tip_tehn WHEN 'M' THEN 'Material' WHEN 'P' THEN 'Produs' WHEN 'S' THEN 'Serviciu prestat' ELSE 'Altele' END as Den_tip_tehn
from tehn t
go
--/*
drop proc yso_xIaTehn 
go
create proc yso_xIaTehn as
select *
from yso_vIaTehn
go
if exists (select * from sysobjects where name ='yso_xImportTehn')
drop procedure yso_xImportTehn
go
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
go
--*/
--/*
if exists (select * from sysobjects where name ='yso_xScriuTehn')
drop procedure yso_xScriuTehn
go
create procedure yso_xScriuTehn @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try
	update v
	set Cod_tehn=t.Cod_tehn, Denumire=t.Denumire, Tip_tehn=t.Tip_tehn
	from tehn v inner join ##importXlsDifTmp t on v.Cod_tehn=t.Cod_tehn
	where t._nrdif=@_nrdif
	if (@@ROWCOUNT=0)
		insert tehn
		(Cod_tehn, Denumire, Tip_tehn, Utilizator, Data_operarii, Ora_operarii, Data1, Data2, Alfa1, Alfa2, Alfa3, Alfa4, Alfa5, Val1, Val2, Val3, Val4, Val5)
		select
		Cod_tehn, Denumire, Tip_tehn, 'IMPORT', GETDATE(), '', '', '', '', '', '', '', '', '', '', '', '', ''
		from ##importXlsDifTmp t
		where t._nrdif=@_nrdif
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.Cod_tehn=t.Cod_tehn and d.Denumire=t.Denumire and d.Tip_tehn=t.Tip_tehn
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
go
--*/
-- exec yso_xScriuTabela 'tehn','d:\BAZA_DATE_ASIS\EXCEL\IMPORT\testimport.xlsx'