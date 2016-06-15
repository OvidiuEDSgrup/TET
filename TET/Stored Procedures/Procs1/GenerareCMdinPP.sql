--***
create procedure GenerareCMdinPP @numarPP varchar(20), @dataPP datetime, @cod char(20), @cantitate float, @lm char(9) 
as        
declare @subunitate char(9),@tip char(2),@numar varchar(20), @data datetime, @userASiS varchar(20), @gestiune char(13),
		@fXML xml, @numarCM varchar(20),@err int,@codbare char(1),@gestiunetmp varchar(13),@gestiuneMP varchar(20)
-- parametri necesari: numar, data, cod, cantitate, lm - de pe pozitia de predare
-- @gestiune MP: poate fi suprascrisa mai jos!
-- @numar (de consum) poate fi atribuit cum se doreste... am pus: set @numar=@numarPP
-- Atentie! Codurile de pe predari sa aiba tehnologie!
--set @userASiS=dbo.fIaUtilizator(null)
--set @fXML = '<row tip="CM"/>'
--set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
--exec wIauNrDocFiscale @fXML, @numar output
set @numar=@numarPP
set @tip = 'CM'
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output              
set @gestiuneMP='PROD'--isnull((select top 1 valoare from proprietati where tip='utilizator' and cod=@userASiS and Cod_proprietate='GESTMP'),'')

--Pana la urma se doreste ca numarul consumului sa fie egal cu cel al predarii:
set @numarCM=RTRIM(@numar)
if exists (select id from pozTehnologii where tip='T' and cod=@cod)
begin   	
begin try 
	declare @input XMl
	set @input=(select 'CM' as '@tip', @dataPP as '@data',@numarCM as '@numar',@subunitate as '@subunitate', --'1' as '@doar_scriere', 
		(select @gestiuneMP as '@gestiune',rtrim(cod) as '@cod', convert(decimal(16,5),@cantitate*cantitate) as '@cantitate',
                  @cod as '@comanda', @lm as '@lm'
            from pozTehnologii 
            where tip='M' and parinteTop=(select id from pozTehnologii where tip='T' and cod=@cod) 
				and @cantitate*cantitate>=0.001
            for XML path,type )
		for xml path,type)
	declare @sesiune varchar(50)
	set @sesiune=(select MAX(token) from ASiSRIA..sesiuniRIA)
	exec wScriuPozdoc @sesiune,@input
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
end
