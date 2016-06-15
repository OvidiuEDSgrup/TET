--***
create procedure [dbo].[wRecalculareElementeMM] @sesiune varchar(50),@parXML XML      
as      
declare @data_jos datetime, @data_sus datetime, @masina varchar(20), @tip varchar(2), @fisa varchar(10), @data datetime, 
	@comanda_antet varchar(20), @lm_antet varchar(9), @comanda_benef_antet varchar(20), @lm_benef_antet varchar(9),
	@tert_antet varchar(13), @marca_antet varchar(20), @marca_ajutor_antet varchar(20),
	@jurnal_antet varchar(20),
	@numar_pozitie int, @subtip varchar(2), @traseu varchar(20), @tert varchar(13), @plecare varchar(50), @data_plecarii datetime, 
	@ora_plecarii varchar(20), @sosire varchar(50), @data_sosirii datetime, @ora_sosirii varchar(20), 
	@explicatii varchar(200), @comanda_benef varchar(20), @lm_benef varchar(9), @marca varchar(9), @fetchStatus int,
	@parXMLString varchar(max), @eroare xml


begin try 

/* citesc valori elemente din XML */ 
select	@data_jos = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'),'01/01/1901'),
		@data_sus = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'),'01/01/2999'),
		@masina = isnull(@parXML.value('(/row/@masina)[1]', 'varchar(20)'),'')


declare cursorPozActivitati cursor for
select /* antet */pa.tip, pa.fisa, pa.data, a.masina, a.comanda, a.loc_de_munca, a.comanda_benef, a.lm_benef, a.Tert, a.Marca, a.marca_ajutor
,/* pozitie */ pa.alfa1 as subtip, pa.numar_pozitie, pa.traseu, pa.plecare, pa.data_plecarii, pa.ora_plecarii, pa.sosire,
pa.data_sosirii, pa.ora_sosirii, pa.explicatii, pa.comanda_benef, pa.lm_beneficiar, pa.tert, pa.marca
from pozactivitati pa
inner join activitati a on a.Tip=pa.Tip and a.Fisa=pa.Fisa and a.Data=pa.Data and a.Masina = @masina
where pa.data between @data_jos and @data_sus

open cursorPozActivitati
fetch next from cursorPozActivitati into 
@tip, @fisa, @data, @masina, @comanda_antet, @lm_antet, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
@marca_antet, @marca_ajutor_antet,	
@subtip, @numar_pozitie, @traseu, @plecare, @data_plecarii, @ora_plecarii, @sosire, @data_sosirii, @ora_sosirii, 
@explicatii, @comanda_benef, @lm_benef, @tert, @marca
set @fetchStatus = @@FETCH_STATUS

while @fetchStatus = 0
begin
		/* formez un string xml cu elementele statice*/
	set @parXMLString = /* antet */ '<row tip='+QUOTENAME(rtrim(@tip),'"')+' fisa='+QUOTENAME(rtrim(@fisa),'"')+' data='+QUOTENAME(rtrim(convert(varchar,@data,101)),'"')+' masina='
		+QUOTENAME(rtrim(@masina),'"')+' comanda='+QUOTENAME(rtrim(@comanda_antet),'"')+' lm='+QUOTENAME(rtrim(@lm_antet),'"')+' com_benef='+QUOTENAME(rtrim(@comanda_benef_antet),'"')
		+' lm_benef='+QUOTENAME(rtrim(@lm_benef_antet),'"')+' tert='+QUOTENAME(rtrim(@tert_antet),'"')+' marca='+QUOTENAME(rtrim(@marca_antet),'"')+'>'
		+/* pozitie */ '<row tip='+QUOTENAME(rtrim(@tip),'"')+' subtip='+QUOTENAME(rtrim(@subtip),'"')+' fisa='+QUOTENAME(rtrim(@fisa),'"')
		+' data='+QUOTENAME(rtrim(convert(varchar,@data,101)),'"')+' numar_pozitie='+QUOTENAME(rtrim(CONVERT(varchar,@numar_pozitie)),'"')
		+' traseu='+QUOTENAME(rtrim(@Traseu),'"')+' plecare='+QUOTENAME(rtrim(@plecare),'"')+' data_plecarii='+QUOTENAME(rtrim(convert(varchar,@data_plecarii,101)),'"')+
		+' ora_plecarii='+QUOTENAME(rtrim(@ora_plecarii),'"')+' sosire='+QUOTENAME(rtrim(@sosire),'"')+' data_sosirii='+QUOTENAME(rtrim(convert(varchar,@data_sosirii,101)),'"')
		+' ora_sosirii='+QUOTENAME(rtrim(@ora_sosirii),'"')+' explicatii='+QUOTENAME(rtrim(@explicatii),'"')+' comanda_benef='+QUOTENAME(rtrim(@comanda_benef),'"')
		+' lm_benef='+QUOTENAME(rtrim(@lm_benef),'"')+' tert='+QUOTENAME(rtrim(@tert),'"')+' marca='+QUOTENAME(rtrim(@marca),'"')+' '

		/* adaug elementele dinamice*/
	select @parXMLString= @parXMLString +
		replace(rtrim(ea.Element),' ','_')+'="'+convert(varchar, CONVERT(decimal(12,2),ea.Valoare))+'" '
	from elemactivitati ea where ea.Tip=@tip and ea.Fisa=@fisa and ea.Data=@data and ea.Numar_pozitie=@numar_pozitie
		/* inchid xml-ul format */
	set @parXMLString=@parXMLString+'/></row>'
	
	set @parXML = CONVERT(xml,@parXMLString)
	
	select @parXML as inainte
	exec wCalcElemActivitati '', @parXML output, 1
	select @parXML as dupa 
	exec wScriuElemActivitati @parXML, @tip, @fisa, @data, @numar_pozitie


	fetch next from cursorPozActivitati into 
	@tip, @fisa, @data, @masina, @comanda_antet, @lm_antet, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
	@marca_antet, @marca_ajutor_antet,	
	@subtip, @numar_pozitie, @traseu, @plecare, @data_plecarii, @ora_plecarii, @sosire, @data_sosirii, @ora_sosirii, 
	@explicatii, @comanda_benef, @lm_benef, @tert, @marca
	set @fetchStatus = @@FETCH_STATUS
end

end try
begin catch
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @eroare='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	select @eroare FOR XML RAW
end catch
begin try 
	close cursorPozActivitati 
end try 
begin catch end catch
begin try 
	deallocate cursorPozActivitati 
end try 
begin catch end catch
