--***

create procedure [dbo].[wOPConsum] @sesiune varchar(50), @parXML xml                
as              
declare @subunitate char(9),		
		@userASiS varchar(20), 
		@gestiune char(13), @coddeviz varchar(10),
		@data datetime,@newdata datetime
		
set @coddeviz = isnull(@parXML.value('(/parametri/@coddeviz)[1]','varchar(10)'),'')

exec wIaUtilizator @sesiune,@userASiS
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output              

begin try  
select @coddeviz	
    if exists (select 1 from pozdoc p where p.Numar=@coddeviz and p.Tip='CM')   
			   raiserror('Documentul a fost deja generat! Operatia a fost anulata!',16,1)
			   
	 declare @input XML
	   set @input=(select top 1  rtrim(@coddeviz) as '@numar', 'CM' as '@tip', convert(varchar(20),p.Data_inchiderii,101) as '@data',
		-- (select max(pd.Loc_de_munca) from pozdevauto pd where pd.Cod_deviz=@coddeviz and pd.Loc_de_munca<>'') '@lm',
		 (select cod_gestiune as '@gestiune', 
				 rtrim(p.Cod) as '@cod', 
				 convert(decimal(12,2),p.cantitate) as '@cantitate',
				 convert(decimal(12,3),p.pret_de_stoc) as '@pstoc',
				 rtrim(p.Cont_de_stoc) as '@contstoc',
				 rtrim(p.Cod_intrare) '@codintrare'
		 from pozdevauto p
		 where p.Cod_deviz=@coddeviz for XML path,type)
		 from devauto p	 where p.Cod_deviz=@coddeviz 
		 for xml Path,type)		 		
		 --exec wScriuPozDevizeLucru @sesiune, @input
		 exec wScriuPozDoc @sesiune,@input
		 
	select 'S-a generat documentul '+rtrim(@coddeviz)+' din data '+convert(char(10),GETDATE(),103) as textMesaj for xml raw, root('Mesaje')
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare='wopconsum (linia '+convert(varchar(20),ERROR_LINE())+')'+char(10)+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
