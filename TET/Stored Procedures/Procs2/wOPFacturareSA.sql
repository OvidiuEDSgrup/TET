﻿--***

create procedure [dbo].[wOPFacturareSA] @sesiune varchar(50), @parXML xml                
as              
declare @subunitate char(9),		
		@userASiS varchar(20), @beneficiar varchar(10),
		@gestiune char(13), @coddeviz varchar(10), @tip varchar(10),
		@data datetime, @gservice varchar(9)
		
set @coddeviz = isnull(@parXML.value('(/parametri/@coddeviz)[1]','varchar(10)'),'')
set @beneficiar = isnull(@parXML.value('(/parametri/@beneficiar)[1]','varchar(10)'),'')
set @data = isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'')

exec wIaUtilizator @sesiune,@userASiS output
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output     
set @gservice=(select top 1 valoare from proprietati where tip='UTILIZATOR' and cod_proprietate='GSERVICE' and cod=@userASiS)

begin try    
	if exists (select 1 from pozdoc p where p.Numar=@coddeviz and p.Tip='AP')   
	begin
			   raiserror('Documentul a fost deja generat! Operatia a fost anulata!',16,1)
			   return -1
	end	   
	if @gservice is null
	begin
			   raiserror('Eroare (wOPFacturareSA): Nu aveti definita gestiunea de service!',16,1)
			   return -1
	end

	 declare @input XML
	   set @input=(select top 1  rtrim(@coddeviz) as '@numar', 'AP' as '@tip', convert(char(10),@data,101) as '@data', @gservice as '@gestprim',
		     (select cod_gestiune as '@gestiune', 
		         rtrim(d.beneficiar) as '@tert', 
				 rtrim(pd.Cod) as '@cod', 
				 convert(decimal(12,2),pd.cantitate) as '@cantitate',				
				 rtrim(pd.Cod_intrare) '@codintrare'
			  from pozdevauto pd
		 where pd.Cod_deviz=@coddeviz and tip_resursa='M' 
		 -- pd.Cod='468 or' and Cantitate='1'
		 for XML path,type)
		 from devauto d	 where d.Cod_deviz=@coddeviz 
		 for xml Path,type)		 		
		 exec wScriuPozdoc @sesiune,@input
		 
	update pozdevauto set Numar_consum=@coddeviz, Stare_pozitie=3, Utilizator_consum=@userASiS
	where cod_deviz=@coddeviz and tip_resursa='M'
	select 'S-a generat documentul '+rtrim(@coddeviz)+' din data '+convert(char(10),GETDATE(),103) as textMesaj for xml raw, root('Mesaje')
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare='wOPFacturareSA (linia '+convert(varchar(20),ERROR_LINE())+')'+char(10)+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch