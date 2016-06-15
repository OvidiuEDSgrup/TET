--***
/* procedura genereaza un cod de bare EAN din o plaja interna */
CREATE procedure generareEan @codbare varchar(50) output, @sesiune varchar(50)=null, @parXML xml=null
as
if exists (select 1 from sys.objects where name='generareEanSP' and type='P')
begin
	exec generareEanSP @codbare=@codbare output, @sesiune=@sesiune, @parXML=@parXML
	return
end

declare @UltCodBare varchar(200)

begin try
	exec luare_date_par @tip='AW', @par='ULT.BARCD', @val_l=0, @val_n=0, @val_a=@UltCodbare output

	if isnull(@UltCodBare,'')=''
		set @UltCodBare='100000000001'
	else
		set @UltCodBare=RTRIM(@UltCodBare)
	
	set @codbare=dbo.fnGetEAN(@UltCodBare)

	set @UltCodBare= CONVERT(varchar(20), CONVERT(bigint, @UltCodBare)+1)

	exec setare_par @tip='AW', @par='ULT.BARCD', @denp='Ult.barcode EAN sugerat', @val_l=0, @val_n=0, @val_a=@UltCodbare

end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
