--***
create procedure [dbo].[wOPGenerareTEdinRM] @sesiune varchar(50), @parXML xml                
as              
-- procedura de generare TE din RM pentru câte o gestiune de transfer
declare @subunitate char(9),@tip char(2),@numar varchar(20), @userASiS varchar(20), @gestiune char(9), @gestiuneTE char(9), @gestiuneprim char(9), 
		@numarTE varchar(20),@err int,@codbare char(1),@data datetime,@gestiunetmp varchar(13),@newdata datetime,@lm char(9)

set @numar = ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), '')                
set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')  
set @newdata = ISNULL(@parXML.value('(/parametri/@dataTE)[1]', 'datetime'), '')  
set @gestiuneTE = ISNULL(@parXML.value('(/parametri/@gestiuneTE)[1]', 'varchar(9)'), '')  -- gestiunea pentru care se face generarea
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
		set @numarTE=LTrim(RTrim(CONVERT(char(20), @NrDocFisc)))
end
   	
begin try 
    if not exists (select 1 from pozdoc where Subunitate=@subunitate and tip='RM' and numar=@numar and data=@data and Gestiune=@gestiuneTE and Tip_miscare='I')
       raiserror('Nu exista receptia cu cu numarul si data introduse!',16,1)
    if exists (select 1 from pozdoc where Subunitate=@subunitate and tip='RM' and numar=@numar and data=@data and Gestiune=@gestiuneTE and Tip_miscare='I' and barcod<>'')   
         raiserror('Documentul a fost deja generat! Operatia a fost anulata!',16,1)
    if isnull(@numarTE,'')=''
        raiserror('Trebuie sa introduceti sau sa poata fi atribuit numarul documentului pe care il veti genera!' ,16,1)

	declare @input XMl
	 set @input=(select top 1 rtrim(subunitate) as '@subunitate', 'TE' as '@tip', rtrim(@numarTE) as '@numar', @newdata as '@data',
			(select rtrim(@gestiuneprim) as '@gestprim', rtrim(gestiune) as '@gestiune', rtrim(p.cod) as '@cod',
			convert(decimal(12,2),p.cantitate) as '@cantitate', convert(decimal(12,3),p.pret_de_stoc) as '@pstoc',
			rtrim(p.Cont_de_stoc) as '@contstoc', '' as '@contcorespondent', 
			rtrim(p.Cod_intrare) as '@codintrare'
			from pozdoc p
			where p.Subunitate=@subunitate and p.tip='RM' and p.Numar=@numar and data=@data and Gestiune=@gestiuneTE and Tip_miscare='I' for XML path,type)
		from pozdoc p
		where p.Subunitate=@subunitate and p.tip='RM' and p.Numar=@numar and data=@data and Gestiune=@gestiuneTE and Tip_miscare='I'
		for xml Path,type)

		 exec wScriuPozdoc @sesiune,@input

	update pozdoc set  Stare = case when (Stare in (3,5)) then 4 when (Stare = 2) then 6 else Stare end, Barcod = @numarTE
		where Subunitate = @subunitate and tip='RM' and Numar=@numar and data=@data and Gestiune=@gestiuneTE and Tip_miscare='I'
	select 'S-a generat documentul TE cu numarul '+rtrim(@numarTE)+' din data '+convert(char(10),@newdata,103) as textMesaj for xml raw, root('Mesaje')
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
