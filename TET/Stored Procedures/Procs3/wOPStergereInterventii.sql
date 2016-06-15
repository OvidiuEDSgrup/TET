--***
create procedure [dbo].[wOPStergereInterventii] @sesiune varchar(50), @parXML xml                
as              
-- procedura de stergere interventii generate
declare @dataInterventii datetime, @mesajeroare varchar(1000)
--
set @dataInterventii = ISNULL(@parXML.value('(/parametri/@dataInterventii)[1]', 'datetime'), '')  
--   	
begin try 
    if not exists (select 1 from pozactivitati where data=@dataInterventii and fisa like rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+'%' and Explicatii='GENERAT AUTOMAT')
		begin
			set @mesajeroare='NU exista interventii generate pe data '+convert(char(10),@dataInterventii,103)+' !'
			raiserror(@mesajeroare,16,1)
		end
	else
		begin
			delete from activitati 
			where tip='FI' and fisa like rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+'%' and data=@dataInterventii
			--
			delete from pozactivitati 
			where tip='FI' and fisa like rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+'%' and data=@dataInterventii
			--
			delete from elemactivitati 
			where tip='FI' and fisa like rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+'%' and data=@dataInterventii
			--
			select 'S-au sters interventiile generate anterior pe data '+convert(char(10),@dataInterventii,103) as textMesaj for xml raw, root('Mesaje')
		end
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
