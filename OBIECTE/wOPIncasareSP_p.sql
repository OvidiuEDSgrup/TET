IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wOPIncasareSP_p')
	DROP PROCEDURE wOPIncasareSP_p
GO

CREATE PROCEDURE wOPIncasareSP_p @sesiune VARCHAR(50), @parXML XML
AS
declare @nrformular varchar(10), @userASIS varchar(20), @denFormular varchar(100)

BEGIN TRY
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	select @nrformular=(case when p.Cod_proprietate='UltFormGenIBAP' then rtrim(p.Valoare) else isnull(@nrformular,'') end)
	from proprietati p
	where p.Tip='PROPUTILIZ' and p.Cod=@userASIS and p.Valoare_tupla=''
		and P.Cod_proprietate in ('UltFormGenIBAP')
		
	select top 1 @denFormular=rtrim(a.Denumire_formular) from antform a where a.Numar_formular=@nrformular
	
	select generare=1, formular=RTRIM(@nrformular), denFormular=@denFormular
	for xml raw, root('Date')


END TRY
begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch