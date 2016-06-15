
CREATE PROCEDURE wPreluareCursBNR @sesiune VARCHAR(50), @parXML XML, @cursValute xml output
AS
/**
Exemplu apel procedura 
	1. 
		exec wIaCursValuta '','<row data="2012.06.06" valuta="EUR"/>'
	2. 
		exec wIaCursValuta '','<row data="2012.06.06" valuta="ALL"/>'
		
Rezultat furnizat in forma
	1. 
		<Cursuri>
			<row valuta="EUR" data="2012-07-11T00:00:00" curs="4.5237" />
		</Cursuri>
	2. 
		<Cursuri>
			<row valuta="CNY" data="2012-06-06T00:00:00" curs="0.5608" />
			<row valuta="PLN" data="2012-06-06T00:00:00" curs="1.0273" />
			<row valuta="SEK" data="2012-06-06T00:00:00" curs="0.4958" />
			<row valuta="INR" data="2012-06-06T00:00:00" curs="0.0645" />
			<row valuta="CAD" data="2012-06-06T00:00:00" curs="3.4573" />
			<row valuta="MDL" data="2012-06-06T00:00:00" curs="0.2984" />
			<row valuta="AUD" data="2012-06-06T00:00:00" curs="3.5182" />
			<row valuta="JPY" data="2012-06-06T00:00:00" curs="0.045129" />
			<row valuta="DKK" data="2012-06-06T00:00:00" curs="0.6007" />
			<row valuta="UAH" data="2012-06-06T00:00:00" curs="0.4435" />
			<row valuta="XDR" data="2012-06-06T00:00:00" curs="5.4022" />
			<row valuta="BRL" data="2012-06-06T00:00:00" curs="1.7621" />
			<row valuta="RSD" data="2012-06-06T00:00:00" curs="0.0386" />
			<row valuta="EUR" data="2012-06-06T00:00:00" curs="4.4642" />
			<row valuta="HUF" data="2012-06-06T00:00:00" curs="0.01487" />
			<row valuta="MXN" data="2012-06-06T00:00:00" curs="0.2523" />
			<row valuta="USD" data="2012-06-06T00:00:00" curs="3.5691" />
			<row valuta="ZAR" data="2012-06-06T00:00:00" curs="0.4241" />
			<row valuta="AED" data="2012-06-06T00:00:00" curs="0.9717" />
			<row valuta="CHF" data="2012-06-06T00:00:00" curs="3.7182" />
			<row valuta="XAU" data="2012-06-06T00:00:00" curs="187.3679" />
			<row valuta="CZK" data="2012-06-06T00:00:00" curs="0.1748" />
			<row valuta="RUB" data="2012-06-06T00:00:00" curs="0.1098" />
			<row valuta="KRW" data="2012-06-06T00:00:00" curs="0.003039" />
			<row valuta="NZD" data="2012-06-06T00:00:00" curs="2.724" />
			<row valuta="NOK" data="2012-06-06T00:00:00" curs="0.5871" />
			<row valuta="BGN" data="2012-06-06T00:00:00" curs="2.2825" />
			<row valuta="GBP" data="2012-06-06T00:00:00" curs="5.5175" />
			<row valuta="TRY" data="2012-06-06T00:00:00" curs="1.9424" />
			<row valuta="EGP" data="2012-06-06T00:00:00" curs="0.5908" />
		</Cursuri>
Observatii

		Data se furnizeaza in formatul: YYYY.MM.DD sau YYYY-MM-DD
		Daca la valuta se trece ALL se va returna un tabel cu toate cursurile valutare in acea zi

**/
begin try
	DECLARE @URL VARCHAR(8000), @valuta VARCHAR(10), @data DATETIME, @raspuns varchar(max), @msgEroare varchar(4000)

	SELECT
		@valuta = @parXML.value('(/*/@valuta)[1]', 'varchar(10)'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime')

	SELECT @URL = 'http://mfinante.asis.ro/handlere/CursuriValutare.ashx?'+ISNULL('valuta=' + @valuta,'') + ISNULL('&data=' + replace(CONVERT(VARCHAR(10), @data, 102), '.', '-'),'')
	
	SELECT @raspuns=dbo.httpget(@URL)
	if isnull(len(@raspuns),0)>0
		set @cursValute=convert(XML,@raspuns)		
	
	if isnull(len(convert(varchar(max), @cursValute)),0)=0
		raiserror('Eroare la actualizarea cursului valutar. Serverul nu a returnat informatii.', 16, 1)
end try
begin catch
	set @msgEroare=error_message()+' ('+object_name(@@procid)+')'
	raiserror(@msgEroare, 16, 1)
end catch
