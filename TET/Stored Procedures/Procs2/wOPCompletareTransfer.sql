﻿--***
create procedure [dbo].wOPCompletareTransfer @sesiune varchar(50), @parXML xml                
as              
-- procedura de generare TE din TE pentru câte o gestiune de transfer
declare @subunitate char(9),@tip char(2),@numar char(8), @userASiS varchar(20), @gestiune char(9), @gestiuneTE char(9), @gestiuneprim char(9), 
		@numarTE char(8),@err int,@codbare char(1),@data datetime,@gestiunetmp varchar(13),@newdata datetime,@lm char(9)

set @numar = ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(8)'), '')                
set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')  
set @newdata = ISNULL(@parXML.value('(/parametri/@dataTE)[1]', 'datetime'), '')  
set @gestiuneTE = ISNULL(@parXML.value('(/parametri/@gestprim)[1]', 'varchar(9)'), '')  -- gestiunea pentru care se face generarea
set @gestiuneprim = ISNULL(@parXML.value('(/parametri/@gestiuneprim)[1]', 'varchar(9)'), '')  -- gestiunea in care se face generarea
set @lm=isnull((select Loc_de_munca from gestcor where Gestiune=@gestiuneTE),'')
set @tip = 'TE'
exec wIaUtilizator @sesiune,@userASiS
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output              

--set @numarTE=RTRIM(@numar)
declare @NrDocFisc int, @fXML xml 
begin
	set @fXML = '<row/>'      
	set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')      
	set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')      
	set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')      
	exec wIauNrDocFiscale @fXML, @NrDocFisc output   
	if ISNULL(@NrDocFisc, 0)<>0 
		set @numarTE=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
end
   	
begin try 
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

    if not exists (select 1 from pozdoc where Subunitate=@subunitate and tip='TE' and numar=@numar and data=@data and Gestiune_primitoare=@gestiuneTE and Tip_miscare='E')
       raiserror('Nu exista transferul cu cu numarul si data introduse!',16,1)
    if exists (select 1 from pozdoc where Subunitate=@subunitate and tip='TE' and numar=isnull(@numarTE,'') and data=@newdata and Gestiune=@gestiuneTE and Tip_miscare='E')   
         raiserror('Documentul a fost deja generat! Operatia a fost anulata!',16,1)
    if isnull(@numarTE,'')=''
        raiserror('Trebuie sa introduceti sau sa poata fi atribuit numarul documentului pe care il veti genera!' ,16,1)

	declare @input XMl
	 set @input=(select top 1 rtrim(subunitate) as '@subunitate', 'TE' as '@tip', rtrim(@numarTE) as '@numar', @newdata as '@data',
			(select rtrim(@gestiuneprim) as '@gestprim', rtrim(gestiune) as '@gestiune', rtrim(p.cod) as '@cod',
			convert(decimal(12,2),p.cantitate) as '@cantitate', convert(decimal(12,3),p.pret_de_stoc) as '@pstoc',
			rtrim(p.Cont_de_stoc) as '@contstoc', '' as '@contcorespondent', 
			rtrim(p.Cod_intrare) as '@codintrare',
			/*startsp*/RTRIM(p.Loc_de_munca) as '@lm'/*stopsp*/
			from pozdoc p
			where p.Subunitate=@subunitate and p.tip='TE' and p.Numar=@numar and data=@data and Gestiune_primitoare=@gestiuneTE and Tip_miscare='E' for XML path,type)
		from pozdoc p
		where p.Subunitate=@subunitate and p.tip='TE' and p.Numar=@numar and data=@data and Gestiune_primitoare=@gestiuneTE and Tip_miscare='E'
		for xml Path,type)

		 exec wScriuPozdoc @sesiune,@input

	update pozdoc set  Stare = case when (Stare in (3,5)) then 4 when (Stare = 2) then 6 else Stare end--, Barcod = @numarTE
		where Subunitate = @subunitate and tip='TE' and Numar=@numar and data=@data and Gestiune_primitoare=@gestiuneTE and Tip_miscare='E'
	select 'S-a generat documentul TE cu numarul '+rtrim(@numarTE)+' din data '+convert(char(10),@newdata,103) as textMesaj for xml raw, root('Mesaje')
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
