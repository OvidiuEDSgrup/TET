--***
create procedure wIaWebTraduceri @sesiune varchar(50), @parXML xml
as
begin try

	declare
		@utilizator varchar(20), @mesajEroare varchar(500), @f_limba varchar(50),
		@f_textOriginal varchar(100), @f_textTradus varchar(100)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@f_limba = isnull(@parXML.value('(/row/@f_limba)[1]', 'varchar(50)'), ''),
		@f_textOriginal = isnull(@parXML.value('(/row/@f_textOriginal)[1]', 'varchar(100)'), ''),
		@f_textTradus = isnull(@parXML.value('(/row/@f_textTradus)[1]', 'varchar(100)'), '')

	select
		rtrim(Limba) as Limba, rtrim(Textoriginal) as Textoriginal, rtrim(Texttradus) as Texttradus
	from webTraduceri
	where (@f_limba = '' or Limba like '%' + @f_limba + '%')
		and (@f_textOriginal = '' or Textoriginal like '%' + @f_textOriginal + '%')
		and (@f_textTradus = '' or Texttradus like '%' + @f_textTradus + '%')
	for xml raw

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE() + ' (wIaWebTraduceri)'
	raiserror(@mesajEroare, 16 ,1)
end catch
