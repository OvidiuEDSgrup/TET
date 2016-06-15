--***
create procedure wOPGenerareCMdinRM @sesiune varchar(50), @parXML xml                
as              
declare @subunitate char(9),@tip char(2),@numar varchar(20), @userASiS varchar(20), @gestiune char(13), @lm varchar(50), 
		@numarCM varchar(20),@err int,@codbare char(1),@data datetime,@gestiunetmp varchar(13),@newdata datetime

set @numar = ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), '')                
set @lm = nullif(@parXML.value('(/parametri/@lm)[1]', 'varchar(50)') ,'')
set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')  
----in cazul in care nu exista campul de tip datafield @dataCM in macheta sa se faca generarea la data curenta.
set @newdata = ISNULL(@parXML.value('(/parametri/@dataCM)[1]', 'datetime'), getdate())  
set @tip = 'CM'
exec wIaUtilizator @sesiune,@userASiS
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output              

--Pana la urma se doreste ca numarul consumului sa fie egal cu cel al receptiei:
set @numarCM=RTRIM(@numar)
   	
begin try 
    if not exists (select 1 from doc where Subunitate=@subunitate and tip='RM' and numar=@numar and data=@data)
       raiserror('Numarul nu exista pentru data introdusa!',16,1)
    if exists (select 1 from pozdoc where Subunitate=@subunitate and tip='RM' and numar=@numar and data=@data and barcod<>'')   
         raiserror('Documentul a fost deja generat! Operatia a fost anulata!',16,1)
    if @numar=''
        raiserror('Trebuie sa introduceti numarul documentului pe care il veti genera!' ,16,1)

	declare @input XMl
	 set @input=(select top 1 rtrim(subunitate) as '@subunitate','CM' as '@tip', @lm '@lm',
		@numarCM as '@numar', @newdata as '@data',
		 (select  rtrim(gestiune) as '@gestiune',rtrim(p.cod) as '@cod',
		 convert(decimal(12,2),p.cantitate) as '@cantitate',
		 convert(decimal(12,3),p.pret_de_stoc) as '@pstoc',
		 rtrim(p.Cont_de_stoc) as '@contstoc',
		 rtrim(p.Cod_intrare) as '@codintrare'
		 from pozdoc p		
		 where p.Subunitate='1' and p.tip='RM' and p.Numar=@numar for XML path,type)
		 from pozdoc p
		 where p.Subunitate='1' and p.tip='RM' and p.Numar=@numar
		 for xml Path,type)

		 exec wScriuPozdoc @sesiune,@input

	update pozdoc             
	 set  Stare = case when (Stare in (3,5)) then 4 when (Stare = 2) then 6 else Stare end, Barcod = @numarCM
		 where Subunitate = @subunitate and pozdoc.tip='RM' and Numar=@numar and data=@data
	select 'S-a generat documentul CM cu numarul '+rtrim(@numarCM)+' din data '+convert(char(10),@newdata,103) as textMesaj for xml raw, root('Mesaje')
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
