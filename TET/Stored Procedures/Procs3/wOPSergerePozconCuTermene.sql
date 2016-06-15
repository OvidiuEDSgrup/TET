--***
create procedure wOPSergerePozconCuTermene @sesiune varchar(50), @parXML xml 
as     
begin try 
declare @numar varchar(20),@tert varchar(20),@subunitate varchar(20), @TermPeSurse int,@data datetime,@tip varchar(2),@sursa varchar(13),@cod varchar(13),@numarpoz int 

set @TermPeSurse=isnull((select top 1 Val_logica from par where tip_parametru='UC' and parametru='POZSURSE'),0)
select @numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),
	   @tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''), 
	   @tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), ''),
	   @sursa=ISNULL(@parXML.value('(/parametri/@sursa)[1]', 'varchar(20)'), ''),
	   @cod=ISNULL(@parXML.value('(/parametri/@cod)[1]', 'varchar(20)'), ''),
	   @data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
	   @subunitate=ISNULL(@parXML.value('(/parametri/@subunitate)[1]', 'varchar(9)'), '1')

	if @sursa='' or @cod='' or not exists(select cod from surse where cod=@sursa) or not exists (select cod from nomencl where cod=@cod)
		raiserror('Campurile de pe macheta nu au fost completate corect!!',11,1)
	
	if (select stare from con where subunitate=@subunitate and tip=@tip and Contract=@numar and Tert=@tert and data=@data )<>0
		raiserror('Nu pot fi sterse termene care apartin unui contract care nu este in starea 0-Operat!!',11,1)
	------------------sterg termenele ----------------
	set @numarpoz=isnull((select max(numar_pozitie) 
			from pozcon 
			where subunitate=@subunitate and tip=@tip and Contract=@numar and Tert=@tert and Cod=@cod and data=@data and Mod_de_plata=@sursa or @sursa=''),0)
	
	if exists( select 1 from termene where subunitate=@subunitate and tip=@tip and Contract=@numar and Tert=@tert and data=@data and Val2=1
									   and Cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numarpoz)) end))
	  raiserror('Nu pot fi sterse termene daca acestea au fost realizate!!',11,1)
			
	delete termene
	where subunitate=@subunitate and tip=@tip and Contract=@numar and Tert=@tert and data=@data
	  and Cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numarpoz)) end)
	
	-------------sterg pozitia din contract------------  
	delete pozcon
	where subunitate=@subunitate and tip=@tip and Contract=@numar and Tert=@tert and Cod=@cod and data=@data and Mod_de_plata=@sursa
	  
	-------------refac suma din con--------------
	update con set Total_contractat=isnull((select SUM(round(cantitate*pret,2)) from Termene 
	                                        where subunitate=@subunitate and tip=@tip and contract=@numar and tert=@tert and data=@data),0)
	where tip=@tip and contract=@numar and tert=@tert and data=@data and subunitate=@subunitate	  
			
end try
begin catch
declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 11, 1)
end catch
