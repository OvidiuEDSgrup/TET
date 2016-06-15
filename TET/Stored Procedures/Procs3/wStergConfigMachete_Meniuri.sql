--***
create procedure wStergConfigMachete_Meniuri @sesiune varchar(50), @parXML XML  
as  

declare @eroare varchar(max)
begin try
--/*
	select 'Stergere meniu' nume, 'CFGMACHETE' as codmeniu, 'NI' as tip, 'ST' subtip, 'O' tipmacheta, @parXML dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	--*/
/*	select 'Antet document' nume, 'DO' codmeniu, 'AD' tip, 'AD' subtip, 'O' tipmacheta--, (select @importXML for xml raw, type) dateInitializare
	for xml raw('deschideMacheta'), root('Mesaje')*/
end try
begin catch
	select @eroare=error_message()+' (wStergConfigMachete_Meniuri)'
	raiserror(@eroare,16,1)
end catch
